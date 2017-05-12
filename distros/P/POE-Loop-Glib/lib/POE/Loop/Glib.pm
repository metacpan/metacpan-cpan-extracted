# Glib event loop bridge for POE::Kernel.

# Empty package to appease perl.
package POE::Loop::Glib;
use strict;
use warnings;

use POE::Kernel; # for MakeMaker
use vars qw($VERSION);
$VERSION = '0.038';

# Include common signal handling.
use POE::Loop::PerlSignals;

# Everything plugs into POE::Kernel.
package # Hide from Pause
  POE::Kernel;
use strict;
use warnings;
no warnings 'redefine';

# Fixes RT#55279
use Glib;

my $_watcher_timer;
my $_idle_timer;
my @fileno_watcher;

# Loop construction and destruction.

sub loop_finalize {
  foreach my $fd (0..$#fileno_watcher) {
    next unless defined $fileno_watcher[$fd];
    foreach my $mode (MODE_RD, MODE_WR, MODE_EX) {
      POE::Kernel::_warn(
        "Mode $mode watcher for fileno $fd is defined during loop finalize"
      ) if defined $fileno_watcher[$fd]->[$mode];
    }
  }
}


# Maintain time watchers.
sub loop_resume_time_watcher {
  my ($self, $next_time) = @_;
  my $now = time;

  my $next = $next_time - $now;
  $next *= 1000;
  $next = 0 if $next < 0;

  if (defined $_watcher_timer) {
        Glib::Source->remove($_watcher_timer);
  }
  $_watcher_timer = Glib::Timeout->add($next, \&_loop_event_callback);
}

# we remove the old Glib::Timeout anyway, so resume amounts to
# the same thing as reset.
*loop_reset_time_watcher = \*loop_resume_time_watcher;

sub _loop_resume_timer {
  Glib::Source->remove($_idle_timer);
  $_idle_timer = undef;
  $poe_kernel->loop_resume_time_watcher($poe_kernel->get_next_event_time());
}

sub loop_pause_time_watcher {
  # does nothing
}


# Maintain filehandle watchers.
sub loop_watch_filehandle {
  my ($self, $handle, $mode) = @_;
  my $fileno = fileno($handle);

  # Overwriting a pre-existing watcher?
  if (defined $fileno_watcher[$fileno]->[$mode]) {
    Glib::Source->remove($fileno_watcher[$fileno]->[$mode]);
    undef $fileno_watcher[$fileno]->[$mode];
  }

  if (TRACE_FILES) {
    POE::Kernel::_warn "<fh> watching $handle in mode $mode";
  }

  # Register the new watcher.
  $fileno_watcher[$fileno]->[$mode] =
    Glib::IO->add_watch( $fileno,
                         ( ($mode == MODE_RD)
                           ? ( ['G_IO_IN', 'G_IO_HUP', 'G_IO_ERR'],
                               \&_loop_select_read_callback
                             )
                           : ( ($mode == MODE_WR)
                               ? ( ['G_IO_OUT', 'G_IO_ERR'],
                                   \&_loop_select_write_callback
                                 )
                               : ( 'G_IO_HUP',
                                   \&_loop_select_expedite_callback
                                 )
                             )
                         ),
                       );
}

sub loop_ignore_filehandle {
  my ($self, $handle, $mode) = @_;
  my $fileno = fileno($handle);

  if (TRACE_FILES) {
    POE::Kernel::_warn "<fh> ignoring $handle in mode $mode";
  }

  # Don't bother removing a select if none was registered.
  if (defined $fileno_watcher[$fileno]->[$mode]) {
    Glib::Source->remove($fileno_watcher[$fileno]->[$mode]);
    undef $fileno_watcher[$fileno]->[$mode];
  }
}

sub loop_pause_filehandle {
  my ($self, $handle, $mode) = @_;
  my $fileno = fileno($handle);

  if (TRACE_FILES) {
    POE::Kernel::_warn "<fh> pausing $handle in mode $mode";
  }

  Glib::Source->remove($fileno_watcher[$fileno]->[$mode]);
  undef $fileno_watcher[$fileno]->[$mode];
}

sub loop_resume_filehandle {
  my ($self, $handle, $mode) = @_;
  my $fileno = fileno($handle);

  # Quietly ignore requests to resume unpaused handles.
  return 1 if defined $fileno_watcher[$fileno]->[$mode];

  if (TRACE_FILES) {
    POE::Kernel::_warn "<fh> resuming $handle in mode $mode";
  }

  $fileno_watcher[$fileno]->[$mode] =
    Glib::IO->add_watch( $fileno,
                         ( ($mode == MODE_RD)
                           ? ( ['G_IO_IN', 'G_IO_HUP', 'G_IO_ERR'],
                               \&_loop_select_read_callback
                             )
                           : ( ($mode == MODE_WR)
                               ? ( ['G_IO_OUT', 'G_IO_ERR'],
                                   \&_loop_select_write_callback
                                 )
                               : ( 'G_IO_HUP',
                                   \&_loop_select_expedite_callback
                                 )
                             )
                         ),
                       );
  return 1;
}


# Callbacks.

# Event callback to dispatch pending events.
my $last_time = time();

sub _loop_event_callback {
  my $self = $poe_kernel;

  if (TRACE_STATISTICS) {
    # TODO - I'm pretty sure the startup time will count as an unfair
    # amout of idleness.
    #
    # TODO - Introducing many new time() syscalls.  Bleah.
    $self->_data_stat_add('idle_seconds', time() - $last_time);
  }

  $self->_data_ev_dispatch_due();
  $self->_test_if_kernel_is_idle();

  if (defined $_idle_timer) {
    Glib::Source->remove ($_idle_timer);
    $_idle_timer = undef;
  }
  if ($self->get_event_count()) {
    $_idle_timer = Glib::Idle->add(\&_loop_resume_timer);
  }

  $last_time = time() if TRACE_STATISTICS;

  # Return false to stop.
  return 0;
}

# Filehandle callback to dispatch selects.
sub _loop_select_read_callback {
  my $self = $poe_kernel;
  my ($fileno, $tag) = @_;

  if (TRACE_FILES) {
    POE::Kernel::_warn "<fh> got read callback for $fileno";
  }

  $self->_data_handle_enqueue_ready(MODE_RD, $fileno);
  $self->_test_if_kernel_is_idle();

  return 1;
}

sub _loop_select_write_callback {
  my $self = $poe_kernel;
  my ($fileno, $tag) = @_;

  if (TRACE_FILES) {
    POE::Kernel::_warn "<fh> got write callback for $fileno";
  }

  $self->_data_handle_enqueue_ready(MODE_WR, $fileno);
  $self->_test_if_kernel_is_idle();

  return 1;
}


# The event loop itself.
sub loop_do_timeslice {
  die "doing timeslices currently not supported in the Glib loop";
}

my $glib_mainloop;

#------------------------------------------------------------------------------
# Loop construction and destruction.

sub loop_attach_uidestroy {
  my ($self, $window) = @_;

  # Don't bother posting the signal if there are no sessions left.  I
  # think this is a bit of a kludge: the situation where a window
  # lasts longer than POE::Kernel should never occur.
  $window->signal_connect
    ( delete_event =>
      sub {
        if ($self->_data_ses_count()) {
          $self->_dispatch_event(
            $self, $self,
            EN_SIGNAL, ET_SIGNAL, [ 'UIDESTROY' ],
            __FILE__, __LINE__, time(), -__LINE__
          );
        }
        return 0;
      }
    );
}

sub loop_initialize {
  my $self = shift;

  $glib_mainloop = Glib::MainLoop->new unless (Glib::main_depth() > 0);
  Glib->install_exception_handler (\&ex);

}

sub loop_run {
  my $self = shift;

  # fixes RT#49742, thanks dngor for tracking it down!
  if ( $self->_data_ses_count() ) {
    $self->_test_if_kernel_is_idle();
    (defined $glib_mainloop) && $glib_mainloop->run;
      if (defined $POE::Kernel::_glib_loop_exception) {
        my $ex = $POE::Kernel::_glib_loop_exception;
        undef $POE::Kernel::_glib_loop_exception;
        die $ex;
      }
  }
}

sub loop_halt {
  (defined $glib_mainloop) && $glib_mainloop->quit;
}

our $_glib_loop_exception;

sub ex {
  $_glib_loop_exception = shift;
  &loop_finalize;
  &loop_halt;

  return 0;
}

1;
__END__

=for stopwords APOCAL AnnoCPAN CPAN CPANTS GPL Glib's Kwalitee Martijn RT co com diff github maint

=begin poe_tests

sub skip_tests {
  return "Glib tests require the Glib module" if do { eval "use Glib"; $@ };
}

=end poe_tests

=head1 NAME

POE::Loop::Glib - A bridge that supports Glib's event loop from POE

=head1 SYNOPSIS

  die "Don't use this module directly. Please use POE instead.";

=head1 ABSTRACT

A bridge that supports Glib's event loop from POE.

=head1 DESCRIPTION

This class is an implementation of the abstract POE::Loop interface.
It follows POE::Loop's public interface exactly.  Therefore, please
see L<POE::Loop> for its documentation. Also, please look at L<Glib>
for more details on using it.

=head1 SEE ALSO

L<POE>, L<POE::Loop>, L<Glib>, L<Glib::MainLoop>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

  perldoc POE::Loop::Glib

=head2 Websites

=over 4

=item * Search CPAN

L<http://search.cpan.org/dist/POE-Loop-Glib>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/POE-Loop-Glib>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/POE-Loop-Glib>

=item * CPAN Forum

L<http://cpanforum.com/dist/POE-Loop-Glib>

=item * RT: CPAN's Request Tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=POE-Loop-Glib>

=item * CPANTS Kwalitee

L<http://cpants.perl.org/dist/overview/POE-Loop-Glib>

=item * CPAN Testers Results

L<http://cpantesters.org/distro/P/POE-Loop-Glib.html>

=item * CPAN Testers Matrix

L<http://matrix.cpantesters.org/?dist=POE-Loop-Glib>

=item * Git Source Code Repository

This code is currently hosted on github.com under the account "apocalypse". Please feel free to browse it
and pull from it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<http://github.com/apocalypse/perl-poe-loop-glib>

=back

=head2 Bugs

Please report any bugs or feature requests to C<bug-poe-loop-glib at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=POE-Loop-Glib>.  I will be
notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 AUTHOR

Martijn van Beers E<lt>martijn@cpan.orgE<gt>

Apocalypse E<lt>apocal@cpan.orgE<gt> is co-maint and tries to fix bugs :)

This module is based on L<POE::Loop::Gtk> which was written by
Rocco Caputo E<lt>rcaputo@cpan.orgE<gt>, thanks!

=head1 LICENSE

POE::Loop::Glib is released under the GPL version 2.0 or higher.

The full text of the license can be found in the LICENSE file included with this module.

=cut
