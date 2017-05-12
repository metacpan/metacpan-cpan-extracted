package POE::Component::SmokeBox::Uploads::CPAN::Mini;
$POE::Component::SmokeBox::Uploads::CPAN::Mini::VERSION = '1.02';
#ABSTRACT: Obtain uploaded CPAN modules via a CPAN::Mini mirror

use strict;
use warnings;
use POE qw(Wheel::Run);
use Carp;
use CPAN::Mini;

sub spawn {
  my $package = shift;
  my %opts = @_;
  $opts{lc $_} = delete $opts{$_} for keys %opts;
  croak "$package requires an 'event' argument\n" unless $opts{event};
  croak "$package requires a 'remote' argument\n" unless $opts{remote};
  croak "$package requires a 'local' argument\n" unless $opts{local};
  $opts{trace} = 1;
  $opts{errors} = 1;
  $opts{skip_perl} = 0 unless $opts{skip_perl};
  $opts{force} = 1 unless defined $opts{force} and !$opts{force};
  if ( $opts{class} ) {
	eval "require $opts{class}";
	croak "$@\n" if $@;
  }
  else {
	$opts{class} = 'CPAN::Mini';
  }
  my $options = delete $opts{options};
  my $self = bless \%opts, $package;
  $self->{session_id} = POE::Session->create(
        object_states => [
	   $self => { shutdown        => '_shutdown', },
           $self => [ qw(_start _update_mirror _sig_chld _wheel_stdout _wheel_stderr _wheel_close) ],
        ],
        heap => $self,
        ( ref($options) eq 'HASH' ? ( options => $options ) : () ),
  )->ID();
  return $self;
}

sub session_id {
  return $_[0]->{session_id};
}

sub shutdown {
  my $self = shift;
  $poe_kernel->post( $self->{session_id}, 'shutdown' );
  return;
}

sub _shutdown {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  $kernel->alias_remove( $_ ) for $kernel->alias_list();
  $kernel->refcount_decrement( $self->{session_id}, __PACKAGE__ ) unless $self->{alias};  
  $kernel->refcount_decrement( $self->{sender_id}, __PACKAGE__ );
  $self->{_shutdown} = 1;
  $self->{wheel}->kill() if $self->{wheel};
  return;
}

sub _start {
  my ($kernel,$session,$sender,$self) = @_[KERNEL,SESSION,SENDER,OBJECT];
  $self->{session_id} = $session->ID();
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
  $self->{sender_id} = $sender_id;
  $kernel->yield( '_update_mirror' );
  return;
}

sub _update_mirror {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  return if $self->{wheel};
  $self->{buffer} = [];
  $self->{_errors} = [];
  $self->{wheel} = POE::Wheel::Run->new(
	Program => sub { $self->{class}->update_mirror( @_ ); },
	ProgramArgs => [ map { defined $self->{$_} ? ( $_ => $self->{$_} ) : () } qw(remote local skip_perl dirmode force trace errors skip_cleanup) ],
	CloseEvent => '_wheel_close',
	ErrorEvent => '_wheel_close',
	StdoutEvent => '_wheel_stdout',
	StderrEvent => '_wheel_stderr',
  );
  $kernel->sig_child( $self->{wheel}->PID(), '_sig_chld' );
  return;
}

sub _sig_chld {
  my($kernel,$self,$sig,$pid,$exit_val) = @_[KERNEL,OBJECT,ARG0..ARG2];
  return $kernel->sig_handled() if $self->{_shutdown};
  my $data = { };
  for ( @{ $self->{buffer} } ) {
       if ( /^cleaning/ ) {
	  my $path = ( split /\s+/ )[1];
	  next unless $path =~ /\.(tar\.gz|tgz|tar\.bz2|zip)$/;
	  my ($short) = $path =~ m!authors/id/(.+)$!i;
	  next unless $short;
	  push @{ $data->{cleaned} }, $short;
	  next;
       }
       my $line = ( split /\s+/ )[0];
       next unless $line;
       next unless $line =~ /^authors/;
       next unless $line =~ /\.(tar\.gz|tgz|tar\.bz2|zip)$/;
       $line =~ s!authors/id/!!;
       push @{ $data->{uploads} }, $line;
  }
  $data->{buffer} = delete $self->{buffer} if $self->{dump};
  $data->{errors} = delete $self->{_errors} if $self->{dump};
  $data->{status} = $exit_val;
  $kernel->post( $self->{sender_id}, $self->{event}, $data );
  $kernel->delay( '_update_mirror', $self->{interval} || 14400 );
  return $kernel->sig_handled();
}

sub _wheel_close {
  delete $_[OBJECT]->{wheel};
  return;
}

sub _wheel_stdout {
  my ($self,$input) = @_[OBJECT,ARG0];
  push @{ $self->{buffer} }, $input;
  warn $input, "\n" if $self->{debug};
  return;
}

sub _wheel_stderr {
  my ($self,$input) = @_[OBJECT,ARG0];
  push @{ $self->{_errors} }, $input;
  warn $input, "\n" if $self->{debug};
  return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

POE::Component::SmokeBox::Uploads::CPAN::Mini - Obtain uploaded CPAN modules via a CPAN::Mini mirror

=head1 VERSION

version 1.02

=head1 SYNOPSIS

  # Create a CPAN::Mini::Devel mirror
  use strict;
  use warnings;
  use POE qw(Component::SmokeBox::Uploads::CPAN::Mini);
  use Data::Dumper;

  $|=1;

  POE::Session->create(
        package_states => [
          'main' => [qw(_start upload)],
        ],
  );

  $poe_kernel->run();
  exit 0;

  sub _start {
    POE::Component::SmokeBox::Uploads::CPAN::Mini->spawn(
        event => 'upload',
        remote => 'ftp://ftp.funet.fi/pub/CPAN/',
        'local' => '/home/ftp/CPAN/',
        class => 'CPAN::Mini::Devel',
    );
    return;
  }

  sub upload {
    print Dumper( $_[ARG0] );
    return;
  }

=head1 DESCRIPTION

POE::Component::SmokeBox::Uploads::CPAN::Mini is a L<POE> component that maintains a minimal CPAN mirror using
L<CPAN::Mini> and generates events for when new distributions are added to the mirror and distributions are 
removed from the mirror.

The component uses L<POE::Wheel::Run> to run L<CPAN::Mini>'s C<update_mirror> class method.

=head1 CONSTRUCTOR

=over

=item C<spawn>

Takes a number of parameters:

  'event', the event handler in your session where each new upload alert should be sent, mandatory;
  'session', optional if the poco is spawned from within another session;
  'remote', URL to the remote cpan mirror (required)
  'local', path to where the local minicpan will reside (required)
  'interval', the interval in seconds between mirror updates, default is 14400 ( ie. 4 hours );

The 'session' parameter is only required if you wish the output event to go to a different
session than the calling session, or if you have spawned the poco outside of a session.

Other L<CPAN::Mini> options may be specified.

  'class', specify the CPAN::Mini class to use, defaults to CPAN::Mini;
  'force', check all directories, even if indices are unchanged, default is true;
  'skip_perl', skip the major language distributions: perl, parrot, and ponier, default false;

There are some debugging options:

  'debug', if set to true the component will print output from update_mirror();
  'dump', if set to true, the component will add additional fields to the output event;
  'options', pass a hashref of POE::Session options to the component;

Returns an object.

=back

=head1 METHODS

=over

=item C<session_id>

Returns the POE::Session ID of the component.

=item C<shutdown>

Terminates the component.

=back

=head1 INPUT EVENTS

=over

=item C<shutdown>

Terminates the component.

=back

=head1 OUTPUT EVENTS

An event will be triggered each time the local mirror is updated by the component. ARG0 of the event will be a hashref with
the following keys:

  'uploads', an arrayref containing the distributions that were updated;
  'cleaned', an arrayref containing the distributions that were removed;
  'status', the exit code of the update_mirror() fork;

If C<dump> has been set to true in the C<spawn> constructor then these additional keys will be set:

  'buffer', an arrayref containing the STDOUT messages from the update_mirror() call;
  'errors', an arrayref containing the STDERR messages from the update_mirror() call;

=head1 SEE ALSO

L<POE>

L<CPAN::Mini>

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
