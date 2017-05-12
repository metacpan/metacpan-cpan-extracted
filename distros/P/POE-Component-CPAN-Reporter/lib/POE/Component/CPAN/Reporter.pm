package POE::Component::CPAN::Reporter;
$POE::Component::CPAN::Reporter::VERSION = '0.08';
#ABSTRACT: Bringing the power of POE to CPAN smoke testing.

use strict;
use warnings;
use POE qw(Wheel::Run);
use Storable;

my $GOT_KILLFAM;

BEGIN {
	$GOT_KILLFAM = 0;
	eval {
		require Proc::ProcessTable;
		$GOT_KILLFAM = 1;
	};
}

sub spawn {
  my $package = shift;
  my %opts = @_;
  $opts{lc $_} = delete $opts{$_} for keys %opts;
  my $options = delete $opts{options};

  if ( $^O eq 'MSWin32' ) {
    eval    { require Win32; };
    if ($@) { die "Win32 but failed to load:\n$@" }
    eval    { require Win32::Job; };
    if ($@) { die "Win32::Job but failed to load:\n$@" }
    eval    { require Win32::Process; };
    if ($@) { die "Win32::Process but failed to load:\n$@" }
  }

  my $self = bless \%opts, $package;
  $self->{session_id} = POE::Session->create(
	object_states => [
	   $self => { shutdown  => '_shutdown',
		      submit    => '_command',
		      push      => '_command',
		      unshift   => '_command',
		      check     => '_command',
		      indices   => '_command',
	   },
	   $self => [ qw(_start _spawn_wheel _wheel_error _wheel_closed _wheel_stdout _wheel_stderr _wheel_idle _wheel_kill _sig_child _sig_handle) ],
	],
	heap => $self,
	( ref($options) eq 'HASH' ? ( options => $options ) : () ),
  )->ID();
  return $self;
}

sub session_id {
  return $_[0]->{session_id};
}

sub pending_jobs {
  return @{ $_[0]->{job_queue} };
}

sub current_job {
  my $self = shift;
  return unless $self->{_current_job};
  my $item = Storable::dclone( $self->{_current_job} );
  return $item;
}

sub current_log {
  my $self = shift;
  return unless $self->{_wheel_log};
  my $item = Storable::dclone( $self->{_wheel_log} );
  return $item;
}

sub pause_queue {
  my $self = shift;
  $self->{paused} = 1;
}

sub resume_queue {
  my $self = shift;
  my $pause = delete $self->{paused};
  $poe_kernel->post( $self->{session_id}, '_spawn_wheel' ) if $pause;
}

sub paused {
  return $_[0]->{paused};
}

sub statistics {
  my $self = shift;
  my @stats;
  push @stats, $self->{stats}->{$_} for qw(started totaljobs avg_run min_run max_run);
  return @stats if wantarray;
  return \@stats;
}

sub shutdown {
  my $self = shift;
  $poe_kernel->post( $self->{session_id}, 'shutdown' );
}

sub _start {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  $kernel->sig( 'HUP', '_sig_handle' );
  $self->{session_id} = $_[SESSION]->ID();
  if ( $self->{alias} ) {
	$kernel->alias_set( $self->{alias} );
  } else {
	$kernel->refcount_increment( $self->{session_id} => __PACKAGE__ );
  }
  $self->{job_queue} = [ ];
  $self->{idle} = 600 unless $self->{idle};
  $self->{timeout} = 3600 unless $self->{timeout};
  $self->{stats} = {
	started => time(),
	totaljobs => 0,
	avg_run => 0,
	min_run => 0,
	max_run => 0,
	_sum => 0,
  };
  $ENV{PERL_CPAN_REPORTER_DIR} = $self->{reporterdir} if $self->{reporterdir};
  undef;
}

sub _sig_handle {
  $poe_kernel->sig_handled();
}

sub _shutdown {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  $kernel->sig( 'HUP' );
  $kernel->sig( 'KILL' );
  $kernel->alias_remove( $_ ) for $kernel->alias_list();
  $kernel->refcount_decrement( $self->{session_id} => __PACKAGE__ ) unless $self->{alias};
  $kernel->refcount_decrement( $_->{session}, __PACKAGE__ ) for @{ $self->{job_queue} };
  $self->{_shutdown} = 1;
  undef;
}

sub _command {
  my ($kernel,$self,$state,$sender) = @_[KERNEL,OBJECT,STATE,SENDER];
  return if $self->{_shutdown};
  my $args;
  if ( ref( $_[ARG0] ) eq 'HASH' ) {
	$args = { %{ $_[ARG0] } };
  } else {
	$args = { @_[ARG0..$#_] };
  }

  $state = 'push' if $state eq 'submit';

  $args->{lc $_} = delete $args->{$_} for grep { $_ !~ /^_/ } keys %{ $args };

  my $ref = $kernel->alias_resolve( $args->{session} ) || $sender;
  $args->{session} = $ref->ID();

  if ( !$args->{module} and $state !~ /^(check|indices)$/i ) {
	warn "No 'module' specified for $state";
	return;
  }

  unless ( $args->{event} ) {
	warn "No 'event' specified for $state";
	return;
  }

  if ( $state =~ /^(package|author)$/ and !$args->{search} ) {
	warn "No 'search' criteria specified for $state";
	return;
  }

  $args->{submitted} = time();

  if ( $state eq 'check' ) {
    if ( $^O eq 'MSWin32' ) {
	$args->{program} = \&_check_reporter;
	$args->{program_args} = [ $args->{perl} || $self->{perl} || $^X ];
    }
    else {
	my $perl = $args->{perl} || $self->{perl} || $^X;
	$args->{program} = [ $perl, '-MCPAN::Reporter', '-e', 1 ];
    }
    $args->{debug} = 1;
  }
  elsif ( $state eq 'indices' ) {
    $args->{prioritise} = 0 unless $args->{prioritise};
    if ( $^O eq 'MSWin32' ) {
	$args->{program} = \&_reload_indices;
	$args->{program_args} = [ $args->{perl} || $self->{perl} || $^X ];
    }
    else {
	my $perl = $args->{perl} || $self->{perl} || $^X;
	my $code = 'CPAN::Index->reload();';
	$args->{program} = [ $perl, '-MCPAN', '-e', $code ];
    }
  }
  else {
    if ( $^O eq 'MSWin32' ) {
	$args->{program} = \&_test_module;
	$args->{program_args} = [ $args->{perl} || $self->{perl} || $^X, $args->{module} ];
    }
    else {
	my $perl = $args->{perl} || $self->{perl} || $^X;
	my $code = 'my $module = shift; local $CPAN::Config->{test_report} = 1; if ( $CPAN::Config->{build_dir_reuse} && $CPAN::META->can(q{reset_tested}) ) { CPAN::Index->reload; $CPAN::META->reset_tested; } test( $module );';
	$args->{program} = [ $perl, '-MCPAN', '-e', $code, $args->{module} ];
    }
  }

  $kernel->refcount_increment( $args->{session}, __PACKAGE__ );

  $args->{cmd} = $state;

  if ( $state eq 'unshift' or $args->{prioritise} ) {
    unshift @{ $self->{job_queue} }, $args;
  }
  else {
    push @{ $self->{job_queue} }, $args;
  }

  $kernel->yield( '_spawn_wheel' );

  undef;
}

sub _sig_child {
  my ($kernel,$self,$thing,$pid,$status) = @_[KERNEL,OBJECT,ARG0..ARG2];
  push @{ $self->{_wheel_log} }, "$thing $pid $status";
  warn "$thing $pid $status\n" if $self->{debug};
  $kernel->delay( '_wheel_idle' );
  my $job = delete $self->{_current_job};
  $job->{status} = $status;
  my $log = delete $self->{_wheel_log};
  if ( $job->{cmd} eq 'recent' ) {
    pop @{ $log };
    s/\x0D$// for @{ $log };
    $job->{recent} = $log;
  }
  elsif ( $job->{cmd} =~ /^(package|author)$/ ) {
    pop @{ $log };
    s/\x0D$// for @{ $log };
    @{ $job->{results} } = grep { $_ !~ /^\[/ } @{ $log };
  }
  else {
    $job->{log} = $log;
  }
  $job->{end_time} = time();
  unless ( $self->{debug} ) {
    delete $job->{program};
    delete $job->{program_args};
  }
  # Stats
  my $run_time = $job->{end_time} - $job->{start_time};
  $self->{stats}->{max_run} = $run_time if $run_time > $self->{stats}->{max_run};
  $self->{stats}->{min_run} = $run_time if $self->{stats}->{min_run} == 0;
  $self->{stats}->{min_run} = $run_time if $run_time < $self->{stats}->{min_run};
  $self->{stats}->{_sum} += $run_time;
  $self->{stats}->{totaljobs}++;
  $self->{stats}->{avg_run} = $self->{stats}->{_sum} / $self->{stats}->{totaljobs};
  $self->{debug} = delete $job->{global_debug};
  $ENV{PERL_CPAN_REPORTER_DIR} = delete $job->{backup_env} if $job->{reporterdir};
  $kernel->post( $job->{session}, $job->{event}, $job );
  $kernel->refcount_decrement( $job->{session}, __PACKAGE__ );
  $kernel->yield( '_spawn_wheel' );
  $kernel->sig_handled();
}

sub _spawn_wheel {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  return if $self->{wheel};
  return if $self->{_shutdown};
  return if $self->{paused};
  my $job = shift @{ $self->{job_queue} };
  return unless $job;
  if ( $job->{reporterdir} ) {
    $job->{backup_env} = $ENV{PERL_CPAN_REPORTER_DIR};
    $ENV{PERL_CPAN_REPORTER_DIR} = $job->{reporterdir};
  }
  $self->{wheel} = POE::Wheel::Run->new(
    Program     => $job->{program},
    ProgramArgs => $job->{program_args},
    StdoutEvent => '_wheel_stdout',
    StderrEvent => '_wheel_stderr',
    ErrorEvent  => '_wheel_error',
    CloseEvent  => '_wheel_close',
  );
  unless ( $self->{wheel} ) {
	warn "Couldn\'t spawn a wheel for $job->{module}\n";
	$kernel->refcount_decrement( $job->{session}, __PACKAGE__ );
	return;
  }
  if ( defined $job->{debug} ) {
	$job->{global_debug} = delete $self->{debug};
	$self->{debug} = $job->{debug};
  }
  $self->{_wheel_log} = [ ];
  $self->{_current_job} = $job;
  $job->{PID} = $self->{wheel}->PID();
  $job->{start_time} = time();
  $kernel->sig_child( $job->{PID}, '_sig_child' );
  $kernel->delay( '_wheel_idle', 60 ) unless $job->{cmd} eq 'indices';
  undef;
}

sub _wheel_error {
  $poe_kernel->delay( '_wheel_idle' );
  delete $_[OBJECT]->{wheel};
  undef;
}

sub _wheel_closed {
  $poe_kernel->delay( '_wheel_idle' );
  delete $_[OBJECT]->{wheel};
  undef;
}

sub _wheel_stdout {
  my ($self, $input, $wheel_id) = @_[OBJECT, ARG0, ARG1];
  $self->{_wheel_time} = time();
  push @{ $self->{_wheel_log} }, $input;
  warn $input, "\n" if $self->{debug};
  undef;
}

sub _wheel_stderr {
  my ($self, $input, $wheel_id) = @_[OBJECT, ARG0, ARG1];
  $self->{_wheel_time} = time();
  if ( $^O eq 'MSWin32' and !$self->{_current_job}->{GRP_PID} and my ($pid) = $input =~ /(\d+)/ ) {
     $self->{_current_job}->{GRP_PID} = $pid;
     warn "Grp PID: $pid\n" if $self->{debug};
     return;
  }
  push @{ $self->{_wheel_log} }, $input unless $self->{_current_job}->{cmd} eq 'recent';
  warn $input, "\n" if $self->{debug};
  undef;
}

sub _wheel_idle {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  my $now = time();
  if ( $now - $self->{_wheel_time} >= $self->{idle} ) {
    $self->{_current_job}->{idle_kill} = 1;
    $kernel->yield( '_wheel_kill', 'Killing current run due to excessive idle' );
    return;
  }
  if ( $now - $self->{_current_job}->{start_time} >= $self->{timeout} ) {
    $self->{_current_job}->{excess_kill} = 1;
    $kernel->yield( '_wheel_kill', 'Killing current run due to excessive run-time' );
    return;
  }
  $kernel->delay( '_wheel_idle', 60 );
  return;
}

sub _wheel_kill {
  my ($kernel,$self,$reason) = @_[KERNEL,OBJECT,ARG0];
  push @{ $self->{_wheel_log} }, $reason;
  warn $reason, "\n" if $self->{debug};
  if ( $^O eq 'MSWin32' and $self->{wheel} ) {
    my $grp_pid = $self->{_current_job}->{GRP_PID};
    return unless $grp_pid;
    warn Win32::FormatMessage( Win32::GetLastError() )
	unless Win32::Process::KillProcess( $grp_pid, 0 );
  }
  else {
    if ( !$self->{no_grp_kill} ) {
      $self->{wheel}->kill(-9) if $self->{wheel};
    }
    elsif ( $GOT_KILLFAM ) {
      _kill_family( 9, $self->{wheel}->PID() ) if $self->{wheel};
    }
    else {
      $self->{wheel}->kill(9) if $self->{wheel};
    }
  }
  return;
}

sub _check_reporter {
  my $perl = shift;
  my $cmdline = $perl . q{ -MCPAN::Reporter -e 1};
  my $job = Win32::Job->new()
    or die Win32::FormatMessage( Win32::GetLastError() );
  my $pid = $job->spawn( $perl, $cmdline )
    or die Win32::FormatMessage( Win32::GetLastError() );
  warn $pid, "\n";
  my $ok = $job->watch( sub { 0 }, 60 );
  my $hashref = $job->status();
  return $hashref->{$pid}->{exitcode};
}

sub _test_module {
  my $perl = shift;
  my $module = shift;
  my $cmdline = $perl . ' -MCPAN -e "my $module = shift; local $CPAN::Config->{test_report} = 1; if ( $CPAN::Config->{build_dir_reuse} && $CPAN::META->can(q{reset_tested}) ) { CPAN::Index->reload; $CPAN::META->reset_tested; } test( $module );" ' . $module;
  my $job = Win32::Job->new()
    or die Win32::FormatMessage( Win32::GetLastError() );
  my $pid = $job->spawn( $perl, $cmdline )
    or die Win32::FormatMessage( Win32::GetLastError() );
  warn $pid, "\n";
  my $ok = $job->watch( sub { 0 }, 60 );
  my $hashref = $job->status();
  return $hashref->{$pid}->{exitcode};
}

sub _reload_indices {
  my $perl = shift;
  my $cmdline = $perl . ' -MCPAN -e "CPAN::Index->reload();"';
  my $job = Win32::Job->new()
    or die Win32::FormatMessage( Win32::GetLastError() );
  my $pid = $job->spawn( $perl, $cmdline )
    or die Win32::FormatMessage( Win32::GetLastError() );
  warn $pid, "\n";
  my $ok = $job->watch( sub { 0 }, 60 );
  my $hashref = $job->status();
  return $hashref->{$pid}->{exitcode};
}

sub _kill_family {
  my ($signal, @pids) = @_;
  my $pt = Proc::ProcessTable->new;
  my (@procs) =  @{$pt->table};
  my (@kids) = _get_pids( \@procs, @pids );
  @pids = (@pids, @kids);
  kill $signal, reverse @pids;
}

sub _get_pids {
  my($procs, @kids) = @_;
  my @pids;
  foreach my $kid (@kids) {
    foreach my $proc (@$procs) {
      if ($proc->ppid == $kid) {
	my $pid = $proc->pid;
	push @pids, $pid, _get_pids( $procs, $pid );
      }
    }
  }
  @pids;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

POE::Component::CPAN::Reporter - Bringing the power of POE to CPAN smoke testing.

=head1 VERSION

version 0.08

=head1 SYNOPSIS

  use strict;
  use POE qw(Component::CPAN::Reporter Component::SmokeBox::Recent);
  use Getopt::Long;

  $|=1;

  my ($perl, $jobs, $recenturl);

  GetOptions( 'perl=s' => \$perl, 'jobs=s' => \$jobs, 'recenturl' => \$recenturl );

  my @pending;
  if ( $jobs ) {
    open my $fh, "<$jobs" or die "$jobs: $!\n";
    while (<$fh>) {
          chomp;
          push @pending, $_;
    }
    close($fh);
  }

  my $smoker = POE::Component::CPAN::Reporter->spawn( alias => 'smoker' );

  POE::Session->create(
    package_states => [
     'main' => [ qw(_start _stop _results _recent) ],
    ],
    heap => { perl => $perl, pending => \@pending },
  );

  $poe_kernel->run();
  exit 0;

  sub _start {
    my ($kernel,$heap) = @_[KERNEL,HEAP];
    if ( @{ $heap->{pending} } ) {
      $kernel->post( 'smoker', 'submit', { event => '_results', perl => $heap->{perl}, module => $_ } ) 
        for @{ $heap->{pending} };
    }
    else {
      POE::Component::SmokeBox::Recent->recent( 
          url => $recenturl || 'http://www.cpan.org/',
          event => 'recent',
      );
      $kernel->post( 'smoker', 'recent', { event => '_recent', perl => $heap->{perl} } ) 
    }
    undef;
  }

  sub _stop {
    $poe_kernel->call( 'smoker', 'shutdown' );
    undef;
  }

  sub _results {
    my $job = $_[ARG0];
    print STDOUT "Module: ", $job->{module}, "\n";
    print STDOUT "$_\n" for @{ $job->{log} };
    undef;
  }

  sub _recent {
    my ($kernel,$heap,$job) = @_[KERNEL,HEAP,ARG0];
    die $job->{error}, "\n" if $job->{error};
    $kernel->post( 'smoker', 'submit', { event => '_results', perl => $heap->{perl}, module => $_ } )
        for @{ $job->{recent} };
    undef;
  }

=head1 DESCRIPTION

POE::Component::CPAN::Reporter is a POE-based framework around L<CPAN> and L<CPAN::Reporter>.
It receives submissions from other POE sessions, spawns a L<POE::Wheel::Run> to deal with running
L<CPAN::Reporter>, captures the output and returns the results to the requesting session.

Only one job request may be processed at a time. If a job is in progress, any jobs submitted are
added to a pending jobs queue.

By default the component uses POE::Wheel::Run to fork another copy of the currently executing perl,
worked out from $^X. You can specify a different perl executable to use though. MSWin32 users please
see the section of this document relating to your platform.

You are responsible for installing and configuring L<CPAN> and L<CPAN::Reporter> and setting up
a suitable perl smoking environment.

=head1 DEPRECATION NOTICE

POE::Component::CPAN::Reporter has been superceded by L<POE::Component::SmokeBox>. The L<minireporter>
script has been superceded by L<App::SmokeBox::Mini>.

Consider this module deprecated.

=head1 CONSTRUCTOR

=over

=item C<spawn>

Spawns a new component session and waits for requests. Takes the following optional arguments:

  'alias', set an alias to send requests to later;
  'options', specify some POE::Session options;
  'debug', see lots of text on your console;
  'idle', adjust the job idle time ( default: 600 seconds ), before jobs get killed;
  'timeout', adjust the total job runtime ( default: 3600 seconds ), before a job is killed;
  'perl', which perl executable to use as a default, instead of S^X;
  'reporterdir', default path where CPAN::Reporter should look for it's config.ini file;
  'no_grp_kill', set to a true value to disable process group kill;

Returns a POE::Component::CPAN::Reporter object.

=back

=head1 METHODS

=over

=item C<session_id>

Returns the POE::Session ID of the component's session.

=item C<pending_jobs>

In a scalar context returns the number of currently pending jobs. In a list context, returns a list of hashrefs
which are the jobs currently waiting in the job queue.

=item C<current_job>

Returns a hashref containing details of the currently executing smoke job. Returns undef if there isn't a job currently running.

=item C<current_log>

Returns an arrayref of log output from the currently executing smoke job. Returns undef if there isn't a job currently running.

=item C<shutdown>

Terminates the component. Any pending jobs are cancelled and the currently running job is allowed to complete gracefully. Requires no additional parameters.

=item C<pause_queue>

Pauses processing of the jobs. The current job will finish processing, but any pending jobs will not be processed until the queue is resumed. This does not affect the continued submission of jobs to the queue.

=item C<resume_queue>

Resumes the processing of the pending jobs queue if it has been previously paused.

=item C<paused>

Returns a true value if the job queue is paused or a false value otherwise.

=item C<statistics>

Returns some statistical that the component gathers. In a list context returns a list of data. In a scalar
context returns an arrayref of the said data.

The data is returned in the following order:

  The time in epoch seconds when the smoker was started;
  The total number of jobs that have been processed;
  The current average job run time;
  The minimum job run time observed;
  The maximum job run time observed;

=back

=head1 INPUT EVENTS

All the events that the component will accept (unless noted otherwise ) require one parameter, a hashref with the following keys defined ( mandatory requirements are shown ):

  'event', an event name for the results to be sent to (Mandatory);
  'module', a module to test, this is passed to CPAN's test() method
	    so whatever that requires should work (Mandatory);
  'session', which session the result event should go to (Default is the sender);
  'perl', which perl executable to use (Default whatever is in $^X);
  'debug', turn on or off debugging information for this particular job;
  'reporterdir', the path where CPAN::Reporter should look for it's config.ini file;

It is possible to pass arbitrary keys in the hash. These should be proceeded with an underscore to avoid
possible future API clashes.

=over

=item C<submit>

=item C<push>

Inserts the requested job at the end of the queue ( if there is one ).

=item C<unshift>

Inserts the requested job at the head of the queue ( if there is one ). Guarantees that that job is processed next.

=item C<shutdown>

Terminates the component. Any pending jobs are cancelled and the currently running job is allowed to complete gracefully. Requires no additional parameters.

=item C<check>

Checks whether L<CPAN::Reporter> is installed. Takes one parameter a hashref with the following keys
defined:

  'event', an event name for the results to be sent to (Mandatory);
  'session', which session the result event should go to (Default is the sender);
  'perl', which perl executable to use (Default whatever is in $^X);

It is possible to pass arbitrary keys in the hash. These should be proceeded with an underscore to avoid
possible future API clashes.

=item C<indices>

Forces an update of the CPAN indices. Takes one parameter, a hashref with the following keys defined:

  'event', an event name for the results to be sent to (Mandatory);
  'session', which session the result event should go to (Default is the sender);
  'perl', which perl executable to use (Default whatever is in $^X);
  'prioritise', set to 1 to put action at the front of the job queue, default 0;

It is possible to pass arbitrary keys in the hash. These should be proceeded with an underscore to avoid
possible future API clashes.

=back

=head1 OUTPUT EVENTS

Resultant events will have a hashref as ARG0. All the keys passed in as part of the original request will be present
(including arbitrary underscore prefixed ones), with the addition of the following keys:

  'log', an arrayref of STDOUT and STDERR produced by the job;
  'PID', the process ID of the POE::Wheel::Run;
  'status', the $? of the process;
  'submitted', the time in epoch seconds when the job was submitted;
  'start_time', the time in epoch seconds when the job started running;
  'end_time', the time in epoch seconds when the job finished;
  'idle_kill', only present if the job was killed because of excessive idle;
  'excess_kill', only present if the job was killed due to excessive runtime;

The results of a 'recent' request will be same as above apart from an additional key:

  'recent', an arrayref of recently uploaded modules;

The results of a 'package' or 'author' search will be same as other events apart from an additional key:

  'results', an arrayref of the modules returned by the search;

=head1 MSWin32

POE::Component::CPAN::Reporter now supports MSWin32 in the same manner as other platforms. L<Win32::Process> is
used to fix the issues surrounding L<POE::Wheel::Run> and forking alternative copies of the perl executable.

The code is still experimental though. Be warned.

=head1 KUDOS

Many thanks to all the people who have helped me with developing this module.

Especially to Andreas J. König for L<CPAN> and David Golden for L<CPAN::Reporter>

=head1 SEE ALSO

L<POE::Component::SmokeBox>

L<App::SmokeBox::Mini>

L<minireporter>

L<POE>

L<CPAN>

L<CPAN::Reporter>

L<http://cpantest.grango.org/>

L<http://use.perl.org/~BinGOs/journal/>

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
