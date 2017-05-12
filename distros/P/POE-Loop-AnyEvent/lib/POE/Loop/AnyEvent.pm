package POE::Loop::AnyEvent;
{
  $POE::Loop::AnyEvent::VERSION = '0.004';
}
# vim: ts=2 sw=2 expandtab

#ABSTRACT: AnyEvent event loop support for POE

use strict;
use warnings;

use POE::Loop::PerlSignals;

package # Hide from Pause
  POE::Kernel;

use strict;
use warnings;

# According to Paul Evans (IO::Async guy) we should make AnyEvent try
# and detect a loop early before it retardedly tries to load AE::Impl::POE
use AnyEvent;
BEGIN {
  # Remove POE from AnyEvent's list of available models.  AnyEvent may
  # try to load POE since it's available.  This wreaks havoc on
  # things.  Common problems include (a) unexpected re-entrancy in POE
  # initialization; (b) deep recursion as POE tries to dispatch its
  # events with itself.

  @AnyEvent::models = grep { $_->[1] !~ /\bPOE\b/ } @AnyEvent::models;
  AnyEvent::detect();
}

use constant ANYEVENT_6 => $AnyEvent::VERSION >= 6;

my $loop;
my $_watcher_timer;
my $_idle_timer;
my %signal_watcher;
my %handle_watchers;

sub loop_initialize {
}

sub loop_finalize {
  my $self = shift;
}

sub loop_do_timeslice {
}

sub loop_run {
  my $self = shift;
  # Avoid a hang when trying to run an idle Kernel.
  $self->_test_if_kernel_is_idle();
  ( $loop = AnyEvent->condvar )->recv;
}

sub loop_halt {
  $loop->send;
}

sub loop_watch_filehandle {
  my ($self, $handle, $mode) = @_;
  my $fileno = fileno($handle);

  if ($mode == MODE_RD) {

  $handle_watchers{watch_r}{$handle} = AnyEvent->io(
      fh   => $handle,
      poll => 'r',
      cb   =>
        sub {
          my $self = $poe_kernel;
          if (TRACE_FILES) {
            POE::Kernel::_warn "<fh> got read callback for $handle";
          }
          $self->_data_handle_enqueue_ready(MODE_RD, $fileno);
          $self->_test_if_kernel_is_idle();
          return 0;
        },
    );

  }
  elsif ($mode == MODE_WR) {

  $handle_watchers{watch_w}{$handle} = AnyEvent->io(
      fh   => $handle,
      poll => 'w',
      cb   =>
        sub {
          my $self = $poe_kernel;
          if (TRACE_FILES) {
            POE::Kernel::_warn "<fh> got write callback for $handle";
          }
          $self->_data_handle_enqueue_ready(MODE_WR, $fileno);
          $self->_test_if_kernel_is_idle();
          return 0;
        },
    );

  }
  else {
    confess "AnyEvent::io does not support expedited filehandles";
  }
}

sub loop_ignore_filehandle {
  my ($self, $handle, $mode) = @_;
  my $fileno = fileno($handle);

  if ( $mode == MODE_EX ) {
    confess "AnyEvent::io does not support expedited filehandles";
  }

  delete $handle_watchers{ $mode == MODE_RD ? 'watch_r' : 'watch_w' }{$handle};
}

sub loop_pause_filehandle {
  shift->loop_ignore_filehandle(@_);
}

sub loop_resume_filehandle {
  shift->loop_watch_filehandle(@_);
}

sub loop_resume_time_watcher {
  my ($self, $next_time) = @_;
  return unless defined $next_time;
  $next_time -= time();
  $next_time = 0 if $next_time < 0;
  $_watcher_timer = AnyEvent->timer( after => $next_time, cb => \&_loop_event_callback);
}

sub loop_reset_time_watcher {
  my ($self, $next_time) = @_;
  undef $_watcher_timer;
  $self->loop_resume_time_watcher($next_time);
}

sub _loop_resume_timer {
  undef $_idle_timer;
  $poe_kernel->loop_resume_time_watcher($poe_kernel->get_next_event_time());
}

sub loop_pause_time_watcher {
}

# Event callback to dispatch pending events.

sub _loop_event_callback {
  my $self = $poe_kernel;

  $self->_data_ev_dispatch_due();
  $self->_test_if_kernel_is_idle();

  undef $_watcher_timer;

  # Register the next timeout if there are events left.
  if ($self->get_event_count()) {
    $_idle_timer = AnyEvent->idle( cb => \&_loop_resume_timer );
  }

  return 0;
}

1;

__END__

=pod

=head1 NAME

POE::Loop::AnyEvent - AnyEvent event loop support for POE

=head1 VERSION

version 0.004

=head1 SYNOPSIS

  use POE qw( Loop::AnyEvent );

  # The rest of your program goes here.
  # There should be little or no changes necessary.
  # All POE APIs and most modules should work with no changes.

=head1 DESCRIPTION

POE::Loop::AnyEvent replaces POE's default select() event loop with
AnyEvent.  This allows POE programs to transparently use most of the
event loops AnyEvent can provide.

POE::Loop::AnyEvent changes POE's internal implementation without
altering its APIs.  By design, nearly all software that are already
uses POE should continue to work normally without any changes.

=head2 Conflicts

It may seem obvious, but AnyEvent::Impl::POE and POE::Loop::AnyEvent
are mutually exclusive of one another.  Using both would result in a
deadlock as each event system called upon the other in infinite
recursion.

This deadlock also affects AnyEvent's support of Wx and Prima.
AnyEvent doesn't natively support these event loops.  Instead it takes
advantage of POE's more flexible, comprehensive, and open event loop
abstractions.

=head2 Callbacks from AnyEvent to POE

POE::Session's callback() and postback() methods simplify callbacks
from plain-coderef systems like Tk and AnyEvent to POE's named event
handlers.  Please see L<POE::Session> for more details.

=head2 Private Methods

POE::Loop::AnyEvent implements the private POE::Loop API.  Please see
L<POE::Loop> for an explanation of that API, especially if you'd like
to publish support for a new event loop.  POE is structured so that
new event loops can be supported without core distribution changes.

Also see L<POE::Test::Loops> for over 35 test files and more than 490
tests you can use for free when writing new POE::Loop modules.

=for poe_tests sub skip_tests {
  $ENV{POE_EVENT_LOOP} = "POE::Loop::AnyEvent";
  return;
}

=head1 SEE ALSO

L<POE>

L<POE::Kernel>

L<POE::Session>

L<POE::Loop>

L<POE::Test::Loops>

L<AnyEvent>

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
