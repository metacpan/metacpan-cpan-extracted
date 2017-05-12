package POE::Loop::IO_Async;
{
  $POE::Loop::IO_Async::VERSION = '0.004';
}

#ABSTRACT: IO::Async event loop support for POE

use strict;
use warnings;

use POE::Loop::PerlSignals;

# Everything plugs into POE::Kernel.
package # Hide from Pause
  POE::Kernel;

use strict;
use warnings;
use IO::Async::Loop;

my $loop;
my $_watcher_timer;
my $_idle_timer;
my %signal_watcher;

sub loop_initialize {
  my $self = shift;

  $loop = IO::Async::Loop->new;
}

sub loop_finalize {
  my $self = shift;
}

sub loop_do_timeslice {
  my $self = shift;
  $loop->loop_once(@_);
}

sub loop_run {
  my $self = shift;

  # Avoid a hang when trying to run an idle Kernel.
  $self->_test_if_kernel_is_idle();

  while ($self->_data_ses_count()) {
    $self->loop_do_timeslice();
  }
}

sub loop_halt {
  $loop->loop_stop();
}

sub loop_watch_filehandle {
  my ($self, $handle, $mode) = @_;
  my $fileno = fileno($handle);

  if ($mode == MODE_RD) {

    $loop->watch_io(
      handle => $handle,
      on_read_ready =>
        sub {
          my $self = $poe_kernel;
          if (TRACE_FILES) {
            POE::Kernel::_warn "<fh> got read callback for $handle";
          }
          $self->_data_handle_enqueue_ready(MODE_RD, $fileno);
          $self->_test_if_kernel_is_idle();
          # Return false to stop... probably not with this one.
          return 0;
        },
    );

  }
  elsif ($mode == MODE_WR) {

    $loop->watch_io(
      handle => $handle,
      on_write_ready =>
        sub {
          my $self = $poe_kernel;
          if (TRACE_FILES) {
            POE::Kernel::_warn "<fh> got write callback for $handle";
          }
          $self->_data_handle_enqueue_ready(MODE_WR, $fileno);
          $self->_test_if_kernel_is_idle();
          # Return false to stop... probably not with this one.
          return 0;
        },
    );

  }
  else {
    confess "IO::Async does not support expedited filehandles";
  }
}

sub loop_ignore_filehandle {
  my ($self, $handle, $mode) = @_;
  my $fileno = fileno($handle);

  if ( $mode == MODE_EX ) {
    confess "IO::Async does not support expedited filehandles";
  }

  $loop->unwatch_io(
    handle => $handle,
    (
      ( $mode == MODE_RD ) ?
      ( on_read_ready => 1 ) :
      ( on_write_ready => 1 )
    ),
  );

}

sub loop_pause_filehandle {
  shift->loop_ignore_filehandle(@_);
}

sub loop_resume_filehandle {
  shift->loop_watch_filehandle(@_);
}

sub loop_resume_time_watcher {
  my ($self, $next_time) = @_;
  return unless $next_time;
  $_watcher_timer = $loop->enqueue_timer( time => $next_time, code => \&_loop_event_callback);
}

sub loop_reset_time_watcher {
  my ($self, $next_time) = @_;
  $loop->cancel_timer($_watcher_timer) if $_watcher_timer;
  undef $_watcher_timer;
  $self->loop_resume_time_watcher($next_time);
}

sub _loop_resume_timer {
  $loop->unwatch_idle($_idle_timer) if $_idle_timer;
  undef $_idle_timer;
  $poe_kernel->loop_resume_time_watcher($poe_kernel->get_next_event_time());
}

sub loop_pause_time_watcher {
  # does nothing
}

# Event callback to dispatch pending events.

sub _loop_event_callback {
  my $self = $poe_kernel;

  $self->_data_ev_dispatch_due();
  $self->_test_if_kernel_is_idle();

  undef $_watcher_timer;

  # Register the next timeout if there are events left.
  if ($self->get_event_count()) {
    $_idle_timer = $loop->watch_idle( when => 'later', code => \&_loop_resume_timer );
  }

  # Return false to stop.
  return 0;
}

1;


__END__
=pod

=head1 NAME

POE::Loop::IO_Async - IO::Async event loop support for POE

=head1 VERSION

version 0.004

=head1 SYNOPSIS

See L<POE::Loop>.

=head1 DESCRIPTION

POE::Loop::IO_Async implements the interface documented in POE::Loop.
Therefore it has no documentation of its own. Please see POE::Loop for more details.

=for poe_tests sub skip_tests {
  $ENV{POE_EVENT_LOOP} = "POE::Loop::IO_Async";
  return;
}

=head1 SEE ALSO

L<POE>

L<POE::Loop>

L<IO::Async>

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

