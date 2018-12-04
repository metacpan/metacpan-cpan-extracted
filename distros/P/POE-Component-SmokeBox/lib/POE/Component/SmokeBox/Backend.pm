package POE::Component::SmokeBox::Backend;
$POE::Component::SmokeBox::Backend::VERSION = '0.54';
#ABSTRACT: smoker backend to POE::Component::SmokeBox

use strict;
use warnings;
use Carp;
use Storable;
use File::Temp ();
use File::Path qw[rmtree];
use File::Spec;
use POSIX qw( O_CREAT O_RDWR O_RDONLY );         # for SDBM_File
use SDBM_File;
use POE qw[Wheel::Run Filter::Line];
use Digest::SHA qw[sha256_hex];
use Env::Sanctify;
use Module::Pluggable search_path => 'POE::Component::SmokeBox::Backend', sub_name => 'backends', except => 'POE::Component::SmokeBox::Backend::Base';

my $GOT_KILLFAM;
my $GOT_PTY;

BEGIN {
        $GOT_KILLFAM = 0;
        eval {
                require Proc::ProcessTable;
                $GOT_KILLFAM = 1;
        };
        $GOT_PTY = 0;
        eval {
                require IO::Pty;
                $GOT_PTY = 1;
        };
	if ( $^O eq 'MSWin32' ) {
		require POE::Wheel::Run::Win32;

		# MSWin32: Disable critical error popups
		# Thanks to https://rt.cpan.org/Public/Bug/Display.html?id=56547

		# Call kernel32.SetErrorMode(SEM_FAILCRITICALERRORS):
		# "The system does not display the critical-error-handler message box.
		# Instead, the system sends the error to the calling process." and
		# "A child process inherits the error mode of its parent process."
		if ( eval { require Win32API::File } ) {
			Win32API::File->import( qw( SetErrorMode SEM_FAILCRITICALERRORS SEM_NOGPFAULTERRORBOX ) );
			SetErrorMode( SEM_FAILCRITICALERRORS() | SEM_NOGPFAULTERRORBOX() );
		} else {
			warn "Unable to use Win32API::File -> $@";
			warn 'This means sometimes perl.exe will popup a dialog box... Annoying!';
		}
	}
}

my @cmds = qw(check index smoke);

sub check {
  my $package = shift;
  return $package->spawn( @_, command => 'check' );
}

sub index {
  my $package = shift;
  return $package->spawn( @_, command => 'index' );
}

sub smoke {
  my $package = shift;
  return $package->spawn( @_, command => 'smoke' );
}

sub spawn {
  my $package = shift;
  my %opts = @_;
  my $extra = { map { ( $_ => delete $opts{$_} ) } grep { /^\_/ } keys %opts };
  $opts{extra} = $extra;
  $opts{lc $_} = delete $opts{$_} for keys %opts;
  my $options = delete $opts{options};
  unless ( $opts{event} ) {
     carp "The 'event' parameter is a mandatory requirement\n";
     return;
  }
  $opts{idle} = 600 unless $opts{idle};
  $opts{timeout} = 3600 unless $opts{timeout};
  $opts{timer} = 60 unless $opts{timer};
  $opts{reaper} = 30 unless $opts{reaper};
  $opts{type} = 'CPANPLUS::YACSmoke' unless $opts{type};
  $opts{command} = lc $opts{command} || 'check';
  $opts{command} = 'check' unless grep { $_ eq $opts{command} } @cmds;
  $opts{perl} = $^X unless $opts{perl}; # and -e $opts{perl};
  $opts{no_log} = 0 unless $opts{no_log};
  $opts{check_warnings} = 1 unless exists $opts{check_warnings};

  if ( $opts{check_warnings} ) {
     require String::Perl::Warnings;
  }

  if ( $opts{command} eq 'smoke' and !$opts{module} ) {
     carp "You must specify a 'module' with 'smoke'\n";
     return;
  }
  my $self = bless \%opts, $package;
  my @backends = $self->backends();
  my ($type) = grep { /\Q$opts{type}\E$/ } @backends;
  unless ( $type ) {
     carp "No such backend '$opts{type}'\n";
     return;
  }
  eval "require $type;";
  if ( $@ ) {
     carp "Could not load '$type' '$@'\n";
     return;
  }
  $self->{backend} = $type->new();
  unless ( $self->{backend} or $self->{backend}->can($self->{command}) ) {
     croak "Problem loading backend '$type'\n";
     return;
  }
  if ( $self->{backend}->can('digest') ) {
     $self->{_reset_digest} = $self->{backend}->digest();
  }
  my $cmd = $self->{command};
  $self->{program} = $self->{backend}->$cmd;
  unless ( $self->{program} or ref $self->{program} eq 'ARRAY' ) {
     carp "The backend method '$cmd' did not return an arrayref\n";
     return;
  }
  unshift @{ $self->{program} }, $self->{perl};
  push @{ $self->{program} }, $self->{module} if $cmd eq 'smoke';
  $self->{session_id} = POE::Session->create(
     package_states => [
	$self => { shutdown => '_shutdown', },
	$self => [qw(_start _spawn_wheel _wheel_error _wheel_closed _wheel_stdout _wheel_stderr _wheel_idle _wheel_reap _wheel_kill _sig_child)],
     ],
     heap => $self,
     ( ref($options) eq 'HASH' ? ( options => $options ) : () ),
  )->ID();
  return $self;
}

sub session_id {
  return $_[0]->{session_id};
}

sub current_log {
  my $self = shift;
  return unless $self->{_wheel_log};
  my $item = Storable::dclone( $self->{_wheel_log} );
  return $item;
}

sub shutdown {
  my $self = shift;
  $poe_kernel->post( $self->session_id() => 'shutdown' => @_ );
}

sub _start {
  my ($kernel,$sender,$self) = @_[KERNEL,SENDER,OBJECT];
  $self->{session_id} = $_[SESSION]->ID();
  if ( $kernel == $sender and !$self->{session} ) {
	croak "Not called from another POE session and 'session' wasn't set\n";
  }
  my $sender_id;
  if ( $self->{session} ) {
    if ( my $ref = $kernel->alias_resolve( $self->{session} ) ) {
	$sender_id = $ref->ID();
    }
    else {
	croak "Could not resolve 'session' to a valid POE session\n";
    }
  }
  else {
    $sender_id = $sender->ID();
  }
  $kernel->refcount_increment( $sender_id, __PACKAGE__ );
  $self->{session} = $sender_id;
  $kernel->detach_myself() if $kernel != $sender;

  $self->{_wheel_log} = [ ];

  if ( !$self->{_reset_digest} ) {
    $self->_tie_digests();
  }
  else {
    $self->{_digests} = { };
  }

  $self->{_loop_detect} = 0;
  $self->{start_time} = time();

  $kernel->yield( '_spawn_wheel' );
  return;
}

sub _shutdown {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  if ( !$self->{_reset_digest} ) {
    $self->_untie_digests();
  }
  else {
    delete $self->{_digests};
  }
  $self->{term_kill} = 1;
  $kernel->yield( '_wheel_kill', 'Killing current due to component shutdown event' );
  return;
}

# Digests tie and untie

sub _tie_digests {
  my $self = shift;
  $self->{_tempdir} = File::Temp->newdir();
  $self->{_tmpdirname} = $self->{_tempdir}->dirname;
  my $file = File::Spec->catfile( $self->{_tmpdirname}, 'digests.dat' );
  $self->{_digests} = { };
  tie %{ $self->{_digests} }, 'SDBM_File', $file, O_CREAT|O_RDWR, 0644 or die "Could not tie: $!\n";
  return 1;
}

sub _untie_digests {
  my $self = shift;
  if ( $self->{_digests} ) {
    untie %{ $self->{_digests} };
    delete $self->{_digests};
    delete $self->{_tempdir};
    rmtree( $self->{_tmpdirname} ) if -d $self->{_tmpdirname};
  }
  return 1;
}

sub _spawn_wheel {
  my ($kernel,$self) = @_[KERNEL,OBJECT];

  # do we need to process callbacks?
  if ( $self->{do_callback} ) {
    # Ask it if we should process this job or not?
    unless ( $self->{do_callback}->( 'BEFORE', $self ) ) {
      warn "Callback denied job, aborting!\n" if $self->{debug} or $ENV{PERL5_SMOKEBOX_DEBUG};
      my $job = $self->_finalize_job( -1 );
      $job->{cb_kill} = 1;
      $kernel->post( $self->{session}, $self->{event}, $job );
      return;
    }
  }

  # Set appropriate %ENV values before we fork()
  my $sanctify = Env::Sanctify->sanctify(
	env => $self->{env},
	sanctify => [
			'^POE_',
			'^PERL5_SMOKEBOX',
			'^HARNESS_',
			'^(PERL5LIB|TAP_VERSION|TEST_VERBOSE)$',
      '^AUTHOR_TESTING$',
      '^PERL_TEST',
  ] );
  my $type = 'POE::Wheel::Run';
  $type .= '::Win32' if $^O eq 'MSWin32';
  $self->{wheel} = $type->new(
    Program     => $self->{program},
    StdoutEvent => '_wheel_stdout',
    StderrEvent => '_wheel_stderr',
    StdoutFilter => POE::Filter::Line->new( InputLiteral => "\n" ),
    StderrFilter => POE::Filter::Line->new( InputLiteral => "\n" ),
    ErrorEvent  => '_wheel_error',
    CloseEvent  => '_wheel_closed',
    ( $GOT_PTY ? ( Conduit => 'pty-pipe' ) : () ),
  );
  # Restore the %ENV values
  $sanctify->restore();
  $self->{_wheel_time} = time();
  $self->{PID} = $self->{wheel}->PID();
  $kernel->sig_child( $self->{PID}, '_sig_child' );
  $kernel->delay( '_wheel_idle', $self->{timer} ) unless $self->{command} eq 'index';
  return;
}

sub _sig_child {
  my ($kernel,$self,$thing,$pid,$status) = @_[KERNEL,OBJECT,ARG0..ARG2];
  push @{ $self->{_wheel_log} }, "$thing $pid $status" if ! $self->{no_log};
  warn "$thing $pid $status\n" if $self->{debug} or $ENV{PERL5_SMOKEBOX_DEBUG};
  $kernel->sig_handled();
  $kernel->delay( '_wheel_idle' );

  my $job = $self->_finalize_job( $status );

  # do we need to process callbacks?
  if ( $self->{do_callback} ) {
    # Inform the callback that the job is done
    $self->{do_callback}->( 'AFTER', $self, $job );
  }

  $kernel->post( $self->{session}, $self->{event}, $job );
  $kernel->delay( '_wheel_reap' => $self->{reaper} ) if $self->{wheel};
  return;
}

sub _finalize_job {
  my( $self, $status ) = @_;

  $self->{end_time} = time();

  if ( !$self->{_reset_digest} ) {
    $self->_untie_digests();
  }
  else {
    delete $self->{_digests};
  }

  delete $self->{_loop_detect};

  my $job = { };
  $job->{status} = $status;
  $job->{log} = $self->{_wheel_log};
  $job->{$_} = $self->{extra}->{$_} for keys %{ $self->{extra} };
  $job->{$_} = $self->{$_} for grep { $self->{$_} } qw(command env PID start_time end_time idle_kill excess_kill term_kill perl type);
  $job->{program} = $self->{program} if $self->{debug} or $ENV{PERL5_SMOKEBOX_DEBUG};
  $job->{module} = $self->{module} if $self->{command} eq 'smoke';
  $poe_kernel->refcount_decrement( $self->{session}, __PACKAGE__ );

  return $job;
}

sub _wheel_reap {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  warn "wheel reaped\n" if $self->{debug} or $ENV{PERL5_SMOKEBOX_DEBUG};
  delete $self->{wheel};
  return;
}

sub _wheel_error {
  my ($self,$operation,$errnum,$errstr,$wheel_id) = @_[OBJECT,ARG0..ARG3];
  $errstr = "remote end closed" if $operation eq "read" and !$errnum;
  warn "wheel $wheel_id generated $operation error $errnum: $errstr\n" if $self->{debug} or $ENV{PERL5_SMOKEBOX_DEBUG};
  return;
}

sub _wheel_closed {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  $kernel->delay( '_wheel_idle' );
  $kernel->delay( '_wheel_reap' );
  warn "wheel closed\n" if $self->{debug} or $ENV{PERL5_SMOKEBOX_DEBUG};
  delete $self->{wheel};
  return;
}

sub _wheel_stdout {
  my ($self, $input, $wheel_id) = @_[OBJECT, ARG0, ARG1];
  return if $self->{_killed};
  $self->{_wheel_time} = time();
  push @{ $self->{_wheel_log} }, $input if ! $self->{no_log};
  warn $input, "\n" if $self->{debug} or $ENV{PERL5_SMOKEBOX_DEBUG};
  if ( $self->_detect_loop( $input, 'stdout' ) ) {
    $self->{excess_kill} = 1;
    $poe_kernel->yield( '_wheel_kill', 'Killing current run due to detection of looping output' );
  }
  return;
}

sub _wheel_stderr {
  my ($self, $input, $wheel_id) = @_[OBJECT, ARG0, ARG1];
  return if $self->{_killed};
  $self->{_wheel_time} = time();
  push @{ $self->{_wheel_log} }, $input if ! $self->{no_log};
  if ( $self->{debug} or $ENV{PERL5_SMOKEBOX_DEBUG} ) {
    if ( length( $input ) > 5000 ) {
      warn "[SUPPRESSED OUTPUT > 5000]\n";
    }
    else {
      warn $input, "\n";
    }
  }
  if ( $self->_detect_loop( $input, 'stderr' ) ) {
    $self->{excess_kill} = 1;
    $poe_kernel->yield( '_wheel_kill', 'Killing current run due to detection of looping output' );
  }
  return;
}

sub _detect_loop {
  my $self = shift;
  my $input = shift || return;
  my $handle = shift || 'stdout';
  return if $self->{_loop_detect};
  if ( my $reset = $self->{_reset_digest} ) {
    if ( eval { $input =~ $reset } ) {
      warn "Resetting digests\n" if $self->{debug} or $ENV{PERL5_SMOKEBOX_DEBUG};
      $self->{_digests} = { };
    }
  }
  return if $input =~ /^\[(MSG|ERROR)\]/;
  my $digest = sha256_hex( $input );

  my $weighting;
  if ( $self->{check_warnings} and length( $input ) <= 5000 ) {
    $weighting = ( $handle eq 'stderr' and String::Perl::Warnings::is_warning($input) ) ? 1 : 10;
  } else {
    $weighting = $handle eq 'stderr' ? 1 : 10;
  }

  if ( exists $self->{_digests}->{ $digest } ) {
    $self->{_digests}->{ $digest } += $weighting;
  }
  else {
    $self->{_digests}->{ $digest } = $weighting;
  }
  return unless ++$self->{_digests}->{ $digest } > 3000;
  return $self->{_loop_detect} = 1;
}

sub _wheel_idle {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  my $now = time();
  if ( $now - $self->{_wheel_time} >= $self->{idle} ) {
    $self->{idle_kill} = 1;
    $kernel->yield( '_wheel_kill', 'Killing current run due to excessive idle' );
    return;
  }
  if ( $now - $self->{start_time} >= $self->{timeout} ) {
    $self->{excess_kill} = 1;
    $kernel->yield( '_wheel_kill', 'Killing current run due to excessive run-time' );
    return;
  }
  $kernel->delay( '_wheel_idle', 60 );
  return;
}

sub _wheel_kill {
  my ($kernel,$self,$reason) = @_[KERNEL,OBJECT,ARG0];
  return if $self->{_killed};
  $self->{_killed} = 1;
  push @{ $self->{_wheel_log} }, $reason if ! $self->{no_log};
  warn $reason, "\n" if $self->{debug} or $ENV{PERL5_SMOKEBOX_DEBUG};
  if ( $^O eq 'MSWin32' and $self->{wheel} ) {
    $self->{wheel}->kill();
  }
  else {
    if ( !$self->{no_grp_kill} ) {
      if ( $^O eq 'solaris' ) {
	 kill( 9, '-' . $self->{wheel}->PID() ) if $self->{wheel};
      }
      else {
         $self->{wheel}->kill(-9) if $self->{wheel};
      }
    }
#    elsif ( $GOT_KILLFAM ) {
#      _kill_family( 9, $self->{wheel}->PID() ) if $self->{wheel};
#    }
    else {
      $self->{wheel}->kill(9) if $self->{wheel};
    }
  }
  return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

POE::Component::SmokeBox::Backend - smoker backend to POE::Component::SmokeBox

=head1 VERSION

version 0.54

=head1 SYNOPSIS

  use strict;
  use warnings;
  use Data::Dumper;
  use POE qw(Component::SmokeBox::Backend);

  my $perl = '/home/cpan/rel/perl-5.8.8/bin/perl';

  POE::Session->create(
    package_states => [
        'main' => [qw(_start _results)],
    ],
  );

  $poe_kernel->run();
  exit 0;

  sub _start {
    my ($kernel,$heap) = @_[KERNEL,HEAP];
    $heap->{backend} = POE::Component::SmokeBox::Backend->smoke(
        event => '_results',
        perl => $perl,
	type => 'CPANPLUS::YACSmoke',
	command => 'smoke',
        module => 'K/KA/KANE/CPANPLUS-0.84.tar.gz',
    );
    return;
  }

  sub _results {
    my ($kernel,$heap,$result) = @_[KERNEL,HEAP,ARG0];
    print Dumper( $result );
    return;
  }

=head1 DESCRIPTION

POE::Component::SmokeBox::Backend is the smoker backend to L<POE::Component::SmokeBox::JobQueue> and
ultimately L<POE::Component::SmokeBox>.

It takes a processes a single CPAN distribution against a given C<perl> executable using a
configurable backend type ( currently, L<CPAN::YACSmoke>, L<CPANPLUS::YACSmoke> or L<CPAN::Reporter> ),
monitors the process for idle ( ie. no output ) or excess runtime, and returns the results to the
requesting L<POE::Session>.

=head1 CONSTRUCTOR

=over

=item C<spawn>

Creates a new POE::Component::SmokeBox::Backend component. Takes a number of parameters:

  'event', the event to return the results to, mandatory;
  'session', specify an alternative POE session to send the results to;
  'command', the backend command to run: check, index, smoke, default is check;
  'perl', the path to the perl executable to use, default is $^X;
  'type', the type of backend to use, default is CPANPLUS::YACSmoke;
  'idle', change the idle timeout, specified in seconds, default is 600;
  'timeout', change runtime timeout, specified in seconds, default is 3600;
  'module', the module to process, mandatory if 'smoke' command is specified;
  'env', a hashref of %ENV values to set when processing;
  'no_log', enable to not store the job output log, default is false;

You may also pass in arbitary parameters which will passed back to you in the C<event> specified. These
arbitary parameters must be prefixed with an underscore.

Returns a POE::Component::SmokeBox::Backend object.

=item C<check>

As above, but automagically runs a C<check>.

=item C<index>

As above, but automagically runs an C<index>.

=item C<smoke>

As above, but automagically runs an C<smoke>.

=back

=head1 METHODS

=over

=item C<session_id>

Returns the component's L<POE::Session> ID.

=item C<shutdown>

Terminates the component. The current job is killed as a result.

=item C<current_log>

Returns an arrayref containing lines of output from the current job.

=back

=head1 INPUT EVENTS

=over

=item C<shutdown>

Terminates the component. The current job is killed as a result.

=back

=head1 OUTPUT EVENTS

ARG0 of the C<event> specified in one of the constructors will be a hashref with the following keys:

  'log', an arrayref of STDOUT and STDERR produced by the job;
  'PID', the process ID of the POE::Wheel::Run;
  'status', the $? of the process;
  'start_time', the time in epoch seconds when the job started running;
  'end_time', the time in epoch seconds when the job finished;
  'idle_kill', only present if the job was killed because of excessive idle;
  'excess_kill', only present if the job was killed due to excessive runtime;
  'term_kill', only present if the job was killed due to a poco shutdown event;
  'cb_kill', only present if the job was killed due to the callback returning false;

Plus any of the parameters given to one of the constructors, including arbitary ones.

=head1 ENVIRONMENT

Setting the environment variable C<PERL5_SMOKEBOX_DEBUG> will cause the component to spew out lots of
information on STDERR.

=head1 SEE ALSO

L<POE::Component::SmokeBox>

L<POE::Component::SmokeBox::Backend::Base>

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
