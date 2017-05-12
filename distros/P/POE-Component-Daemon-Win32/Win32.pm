package POE::Component::Daemon::Win32;

use strict;
use Carp;
use Exporter;
use Win32::Daemon;
use POE;

use vars qw( $VERSION @ISA @EXPORT %SERVICE_STATES );

use constant DEFAULT_ALIAS          => 'win32daemon';
use constant DEFAULT_POLL_INTERVAL  => 1;
use constant DEFAULT_SHUTDOWN_DELAY => 30 * 1000;

@ISA = qw( Exporter );
@EXPORT = @Win32::Daemon::EXPORT;
$VERSION = '0.01';
%SERVICE_STATES = (
  not_ready        => SERVICE_NOT_READY,
  stopped          => SERVICE_STOPPED,
  running          => SERVICE_RUNNING,
  paused           => SERVICE_PAUSED,
  start_pending    => SERVICE_START_PENDING,
  stop_pending     => SERVICE_STOP_PENDING,
  continue_pending => SERVICE_CONTINUE_PENDING,
  pause_pending    => SERVICE_PAUSE_PENDING
);

sub spawn {

  my ($class, %args) = @_;

  $args{'Alias'}        ||= DEFAULT_ALIAS;
  $args{'PollInterval'} ||= DEFAULT_POLL_INTERVAL;

  my %callback;

  unless (defined $args{'Callback'}) {

    croak 'POE::Component::Daemon::Win32 "Callback" parameter missing';

  }

  if (ref $args{'Callback'} eq 'HASH') {

    %callback = %{$args{'Callback'}};

  } elsif (ref $args{'Callback'} eq 'CODE') {

    %callback = map { $_ => $args{'Callback'} } ('shutdown', keys %SERVICE_STATES);

  } else {

    croak 'POE::Component::Daemon::Win32 "Callback" parameter must be a HASHREF or CODEREF';

  }

  POE::Session->create (
    inline_states => {
      _start                   => \&_start,
      _stop                    => \&_stop,
      shutdown                 => \&shutdown,
      poll                     => \&poll,
      state                    => \&state,
      next_state               => \&next_state,

      service_not_ready        => \&service_not_ready,
      service_running          => \&service_running,
      service_paused           => \&service_paused,
      service_start_pending    => \&service_start_pending,
      service_stop_pending     => \&service_stop_pending,
      service_pause_pending    => \&service_pause_pending,
      service_continue_pending => \&service_continue_pending,
      service_stopped          => \&service_stopped,
      service_unhandled        => \&service_unhandled,
      service_shutdown         => \&service_shutdown

    }, args => [ @args{qw( Alias PollInterval )}, \%callback ]
  );

  $args{'Alias'};

}

sub _start {

  my ($kernel, $heap, $session, $alias, $poll_interval, $callback)
    = @_[KERNEL, HEAP, SESSION, ARG0..ARG2]
  ;
  $heap->{'Alias'} = $alias;
  $heap->{'PollInterval'} = $poll_interval;
  $heap->{'Callback'} = $callback;
  $kernel->alias_set ($alias);
  $heap->{'last_state'} = SERVICE_START_PENDING;
  Win32::Daemon::StartService();
  $kernel->delay (poll => $heap->{'PollInterval'});

}

sub _stop {}

sub poll {

  my ($kernel, $heap) = @_[KERNEL, HEAP];
  my $state = Win32::Daemon::State();

  if (SERVICE_RUNNING == $state) {

    $kernel->yield ('service_running', $state);

  } elsif (SERVICE_NOT_READY) {

    $kernel->yield ('service_not_ready', $state);

  } elsif (SERVICE_START_PENDING == $state) {

    $kernel->yield ('service_start_pending', $state);

  } elsif (SERVICE_STOP_PENDING == $state) {

    $kernel->yield ('service_stop_pending', $state);

  } elsif (SERVICE_PAUSE_PENDING == $state) {

    $kernel->yield ('service_pause_pending', $state);

  } elsif (SERVICE_CONTINUE_PENDING == $state) {

    $kernel->yield ('service_continue_pending', $state);

  } elsif (SERVICE_PAUSED == $state) {

    $kernel->yield ('service_paused', $state);

  } elsif (SERVICE_STOPPED == $state) {

    $kernel->yield ('service_stopped', $state);

  } else {

    $kernel->yield ('service_unhandled', $state);

  }

  if (SERVICE_CONTROL_NONE != (
    my $message = Win32::Daemon::QueryLastMessage (1)
  )) {

    if (SERVICE_CONTROL_INTERROGATE == $message) {

      $kernel->yield ('state', $heap->{'last_state'});

    } elsif (SERVICE_CONTROL_SHUTDOWN == $message) {

      $kernel->yield ('service_shutdown', $state, $message);

    }

  }

  $kernel->delay (poll => $heap->{'PollInterval'});

}

sub shutdown {

  my ($kernel, $heap) = @_[KERNEL, HEAP];
  $kernel->alias_remove ($heap->{'Alias'});
  $kernel->alarm_remove_all;

}

sub state {

  my ($kernel, $heap, $state) = @_[KERNEL, HEAP, ARG0];

  if (scalar @_ > ARG0) {

    my $href;

    if (ref $state eq 'HASH') {

      $href = $state;
      $state = $href->{'state'};

    }

    $state = $SERVICE_STATES{$state} unless $state =~ /^\d+$/;
    Win32::Daemon::State ($href || $state);
    $heap->{'last_state'} = $state
      if $state == SERVICE_RUNNING
      || $state == SERVICE_PAUSED
      || $state == SERVICE_STOPPED
    ;

  } else {

    $state = Win32::Daemon::State();

  }

  $state;

}

sub next_state {

  my ($kernel, $heap, $delay) = @_[KERNEL, HEAP, ARG0];
  my $state = Win32::Daemon::State();
  my $message = Win32::Daemon::QueryLastMessage (1);
  my $next_state;

  return if $state == SERVICE_RUNNING
    || $state == SERVICE_NOT_READY
    || $state == SERVICE_PAUSED
    || $state == SERVICE_STOPPED
  ;

  if ($state == SERVICE_START_PENDING) {

    $next_state = SERVICE_RUNNING;

  } elsif ($state == SERVICE_PAUSE_PENDING) {

    $next_state = SERVICE_PAUSED;

  } elsif ($state == SERVICE_CONTINUE_PENDING) {

    $next_state = SERVICE_RUNNING;

  } elsif ($state == SERVICE_STOP_PENDING) {

    $next_state = SERVICE_STOPPED;

  } elsif ($message == SERVICE_CONTROL_SHUTDOWN) {

    $next_state = SERVICE_STOP_PENDING;

    $kernel->yield (state => {
      state    => $next_state,
      waithint => $delay || DEFAULT_SHUTDOWN_DELAY
    });
    return;

  } else {

    return unless defined $heap->{'last_state'};
    $next_state = $heap->{'last_state'};

  }

  $kernel->yield (state => $next_state);

}

# callbacks

sub service_not_ready {

  my ($kernel, $heap) = @_[KERNEL, HEAP];

  if (my $callback = $heap->{'Callback'}->{'not_ready'}) {

    $callback->(@_);

  }

}

sub service_start_pending {

  my ($kernel, $heap) = @_[KERNEL, HEAP];

  if (my $callback = $heap->{'Callback'}->{'start_pending'}) {

    $callback->(@_);

  } else {

    $kernel->yield ('next_state');

  }

}

sub service_stop_pending {

  my ($kernel, $heap) = @_[KERNEL, HEAP];

  if (my $callback = $heap->{'Callback'}->{'stop_pending'}) {

    $callback->(@_);

  } else {

    $kernel->yield ('next_state');

  }

}

sub service_pause_pending {

  my ($kernel, $heap) = @_[KERNEL, HEAP];

  if (my $callback = $heap->{'Callback'}->{'pause_pending'}) {

    $callback->(@_);

  } else {

    $kernel->yield ('next_state');

  }

}

sub service_continue_pending {

  my ($kernel, $heap) = @_[KERNEL, HEAP];

  if (my $callback = $heap->{'Callback'}->{'continue_pending'}) {

    $callback->(@_);

  } else {

    $kernel->yield ('next_state');

  }

}

sub service_running {

  my ($kernel, $heap) = @_[KERNEL, HEAP];

  if (my $callback = $heap->{'Callback'}->{'running'}) {

    $callback->(@_);

  }

}

sub service_stopped {

  my ($kernel, $heap) = @_[KERNEL, HEAP];

  if (my $callback = $heap->{'Callback'}->{'stopped'}) {

    $callback->(@_);

  }

  Win32::Daemon::StopService();
  $kernel->yield ('shutdown');

}

sub service_paused {

  my ($kernel, $heap) = @_[KERNEL, HEAP];

  if (my $callback = $heap->{'Callback'}->{'paused'}) {

    $callback->(@_);

  }

}

sub service_unhandled {

  my ($kernel, $heap) = @_[KERNEL, HEAP];

  if (my $callback = $heap->{'Callback'}->{'unhandled'}) {

    $callback->(@_);

  } else {

    $kernel->yield ('next_state');

  }

}

sub service_shutdown {

  my ($kernel, $heap) = @_[KERNEL, HEAP];

  if (my $callback = $heap->{'Callback'}->{'shutdown'}) {

    $callback->(@_);

  } else {

    $kernel->yield ('next_state');

  }

}

1;
__END__

=head1 NAME

POE::Component::Daemon::Win32 - Run POE as a Windows NT/2000/XP service

=head1 SYNOPSIS

  use POE qw( Component::Daemon::Win32 );

  # generic callback - all events call the same subroutine

  POE::Component::Daemon::Win32->spawn (
    Callback => \&sub
  );

  # state-specific callback

  POE::Component::Daemon::Win32->spawn (
    Callback => {
      start_pending => \&sub1,
      stop_pending  => \&sub2,
      stopped       => \&sub3,
      ...
    }
  );

=head1 DESCRIPTION

POE::Component::Daemon::Win32 enables POE scripts to run as services via the
Win32::Daemon module by Dave Roth.  Full event-based callbacks are available
on service state changes.

=head1 PARAMETERS

The following parameters may be passed to the spawn() constructor:

=over

=item Callback

Specifies which subroutines should be called for any given states.  If a
coderef is passed, all events will call that subroutine.
Alternately, a hashref may be specified.  In this case, the hashref should
contain state names for keys and coderefs for values.  See below for a
list of valid state names.

=item Alias

This optional parameter specifies the alias by which the underlying session
will be known.  If omitted, the alias will be set to a default of
'win32daemon'.

=item PollInterval

This optional parameter sets the frequency (in seconds) of service polls.  If
omitted, polls will occur approximately once every second.

=back

=head1 CALLBACKS

Whenever the Win32 service state changes, events are fired off to the
user-defined callbacks.  Valid callback names are specified below in the STATES
section.

Callbacks can either be defined per-state or can be delegated en masse to a
single subroutine.

  # per-state callback

  sub service_start_pending {

    my $kernel = $_[KERNEL];
    # do some sort of initialization here
    $kernel->yield ('next_state');

  }

  # generic callback

  sub service_state {

    my ($kernel, $state, $message) = @_[KERNEL, ARG0, ARG1];

    # service start pending

    if ($state == SERVICE_START_PENDING) {

      # do some sort of initialization here

    }

    $kernel->yield ('next_state');

  }

The second argument C<$state> contains a number corresponding to the current
service state.  The parameter C<$message> contains any service messages such
as a pending system shutdown.

If you choose the latter, non-state specific approach, you only need to create
one subroutine.  Within the callback just compare the provided state with a
list of service state constants.  Please see the CONSTANTS section below for
a list of valid state constants.

When your script is ready to move on to the next service state, simply notify
the kernel of your intent like so:

  $kernel->yield ('next_state');

If you do not pass on a C<next_state> message, your callback will be invoked
every cycle until you are ready for the next state.  This allows you to take
care of potentially long-running operations safely.

Note, however, that one should not take too long to acknowledge a state change
or the Service Control Manager (SCM) may deem your service unresponsive.  If
this happens it will be impossible to interact with the service short of
forcefully terminating its process.

=head1 STATES

The following states are recognized for use in C<Callback>:

=over

=item not_ready

The Service Control Manager (SCM) is not ready.

Next state: C<start_pending>.

=item start_pending

The SCM expects us to run our startup procedure at this point.

Next state: C<running>.

=item running

Normal operation.  The service should spend the vast majority of its time in
this state.

=item pause_pending

The SCM has informed the service it should pause operation.  This is not to be
confused with the stopped state.

Next state: C<paused>.

=item paused

The service should not perform anything above and beyond SCM interaction
during this state.

=item continue_pending

The service is coming out of the paused state and should resume normal
operation.

Next state: C<running>.

=item stop_pending

The service should start winding down.  Typically one would start closing open
filehandles/connections/etc. and generally cleaning up at this point.

Next state: C<stopped>

=item stopped

The service has stopped.  After any callback has returned, no further
service communications will take place.  The component will then be destroyed.

=item shutdown

The system on which the service is running has been instructed to shut down.
This isn't really a state per se, but rather a message from the SCM.

If the service takes too long to stop, it runs the risk of being forcefully
terminated by the SCM.  By default, approximately 30 seconds are allowed for
graceful service shutdown.  If your service needs more time it should pass a
delay, in milliseconds, with its C<next_state> call.

  # allow 45 seconds for service shutdown

  $kernel->yield ('next_state', 45 * 1000);

=item unhandled

This state is provided to handle any states not specificially supported at this
time.

=back

=head1 CONSTANTS

The following service state constants are supported:

  SERVICE_NOT_READY
  SERVICE_STOPPED
  SERVICE_RUNNING
  SERVICE_PAUSED
  SERVICE_START_PENDING
  SERVICE_STOP_PENDING
  SERVICE_CONTINUE_PENDING
  SERVICE_PAUSE_PENDING

The following service message constant is supported:

  SERVICE_CONTROL_SHUTDOWN

For more information about each state and its purpose, please see
L<Win32::Daemon>.

=head1 AUTHOR

Peter Guzis E<lt>pguzis@cpan.orgE<gt>

=head1 SEE ALSO

L<Win32::Daemon>

=cut
