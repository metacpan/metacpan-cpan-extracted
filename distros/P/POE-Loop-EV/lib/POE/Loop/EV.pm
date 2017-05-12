package POE::Loop::EV;

# EV.pm (libev) event loop bridge
# $Id: EV.pm 27 2008-01-29 19:42:57Z andyg $

use warnings;
use strict;
use POE::Loop::PerlSignals;
use EV;

our $VERSION = '0.14';

my %methods;
sub _backend_name {
    return undef unless defined( my $backend = shift );
    %methods = (
        EV::BACKEND_SELECT()  => 'select',
        EV::BACKEND_POLL()    => 'poll',
        EV::BACKEND_EPOLL()   => 'epoll',
        EV::BACKEND_KQUEUE()  => 'kqueue',
        EV::BACKEND_DEVPOLL() => 'devpoll',
        EV::BACKEND_PORT()    => 'port',
    ) unless keys %methods;
    return $methods{ $backend };
}

=for poe_tests
use EV;
BEGIN { $ENV{POE_EVENT_LOOP} = 'POE::Loop::EV'; $ENV{POE_LOOP_USES_POLL} = 1 if EV::backend() == EV::BACKEND_POLL(); }
sub skip_tests {
    return "wheel_readwrite test disabled for 'kqueue'"
        if EV::backend() == EV::BACKEND_KQUEUE() && $_[0] eq 'wheel_readwrite';
    if ($_[0] eq '00_info') {
        my %methods = ( # duplicated for generated tests
            EV::BACKEND_SELECT()  => 'select',
            EV::BACKEND_POLL()    => 'poll',
            EV::BACKEND_EPOLL()   => 'epoll',
            EV::BACKEND_KQUEUE()  => 'kqueue',
            EV::BACKEND_DEVPOLL() => 'devpoll',
            EV::BACKEND_PORT()    => 'port',
        );
        my $method = $methods{ EV::backend() };
        diag("Using default EV backend '$method'");
    }
    return undef;
}

=cut

# Everything plugs into POE::Kernel.
package # hide me from PAUSE
    POE::Kernel;

# Loop debugging
sub EV_DEBUG () { $ENV{POE_EV_DEBUG} || 0 }

# Global EV timer object
my $_watcher_timer;

# Global list of EV filehandle objects, indexed by fd number
my @fileno_watcher;

my $_async_watcher;

my $DIE_MESSAGE;

############################################################################
# Initialization, Finalization, and the Loop itself
############################################################################

sub loop_initialize {
    my $self = shift;
    
    if ( EV_DEBUG ) {
        my $method = POE::Loop::EV::_backend_name( EV::backend() );
        warn "loop_initialize, EV is using method: $method\n";
    }

    # Set up the global timer object
    $_watcher_timer = EV::periodic( 0, 0, 0, \&_loop_timer_callback );
    
    # Workaround so perl signals are handled
    $_async_watcher = EV::check(sub { });
    
    $EV::DIED = \&_die_handler;
}

# Timer callback to dispatch events.
sub _loop_timer_callback {
    my $self = $poe_kernel;
    
    EV_DEBUG && warn "_loop_timer_callback, at " . time() . "\n";

    $self->_data_ev_dispatch_due();
    $self->_test_if_kernel_is_idle();

    # Transferring control back to EV; this is idle time.
}

sub loop_finalize {
    my $self = shift;
    
    EV_DEBUG && warn "loop_finalize\n";
    
    foreach my $fd ( 0 .. $#fileno_watcher ) {
        next unless defined $fileno_watcher[ $fd ];
        foreach my $mode ( EV::READ, EV::WRITE ) {
            if ( defined $fileno_watcher[ $fd ]->[ $mode ] ) {
                POE::Kernel::_warn(
                    "Mode $mode watcher for fileno $fd is defined during loop finalize"
                );
            }
        }
    }
    
    $self->loop_ignore_all_signals();
    undef $_async_watcher;
}

sub loop_attach_uidestroy {
    # does nothing, no UI
}

sub loop_do_timeslice {
    # does nothing
}

sub loop_run {
    EV_DEBUG && warn "loop_run\n";
    
    EV::run();
    
    if ( defined $DIE_MESSAGE ) {
        my $message = $DIE_MESSAGE;
        undef $DIE_MESSAGE;
        die $message;
    }
}

sub loop_halt {
    EV_DEBUG && warn "loop_halt\n";
    
    $_watcher_timer->stop();
    undef $_watcher_timer;
    
    EV::break();
}

sub _die_handler {
    EV_DEBUG && warn "_die_handler( $@ )\n";
    
    # EV doesn't let you rethrow an error here, so we have
    # to stop the loop and get the error later
    $DIE_MESSAGE = $@;
    
    # This will cause the EV::run call in loop_run to return,
    # and cause the process to die.
    EV::break();
}

############################################################################
# Timer code
############################################################################

sub loop_resume_time_watcher {
    my ( $self, $next_time ) = @_;
    ( $_watcher_timer and $next_time ) or return;
    
    EV_DEBUG && warn "loop_resume_time_watcher( $next_time, in " . ( $next_time - time() ) . " )\n";

    $_watcher_timer->set($next_time);
    $_watcher_timer->start();
}

sub loop_reset_time_watcher {
    my ( $self, $next_time ) = @_;
    ( $_watcher_timer and $next_time ) or return;
    
    EV_DEBUG && warn "loop_reset_time_watcher( $next_time, in " . ( $next_time - time() ) . " )\n";
    
    $_watcher_timer->set($next_time);
    $_watcher_timer->start();
}

sub loop_pause_time_watcher {
    $_watcher_timer or return;
    
    EV_DEBUG && warn "loop_pause_time_watcher()\n";
    
    $_watcher_timer->stop();
}

############################################################################
# Filehandle code
############################################################################

# helper function, not a method
sub _mode_to_ev {
    return EV::READ  if $_[0] == MODE_RD;
    return EV::WRITE if $_[0] == MODE_WR;

    confess "POE::Loop::EV does not support MODE_EX"
        if $_[0] == MODE_EX;

    confess "Unknown mode $_[0]";
}

sub loop_watch_filehandle {
    my ( $self, $handle, $mode ) = @_;

    my $fileno  = fileno($handle);
    my $watcher = $fileno_watcher[ $fileno ]->[ $mode ];

    if ( defined $watcher ) {
        $watcher->stop();
        undef $fileno_watcher[ $fileno ]->[ $mode ];
    }
    
    EV_DEBUG && warn "loop_watch_filehandle( $handle ($fileno), $mode )\n";

    $fileno_watcher[ $fileno ]->[ $mode ] = EV::io(
        $fileno,
        _mode_to_ev($mode),
        \&_loop_filehandle_callback,
    );
}

sub loop_ignore_filehandle {
    my ( $self, $handle, $mode ) = @_;

    my $fileno  = fileno($handle);
    my $watcher = $fileno_watcher[ $fileno ]->[ $mode ];

    return if !defined $watcher;
    
    EV_DEBUG && warn "loop_ignore_filehandle( $handle ($fileno), $mode )\n";

    $watcher->stop();
    
    undef $fileno_watcher[ $fileno ]->[ $mode ];
}

sub loop_pause_filehandle {
    my ( $self, $handle, $mode ) = @_;

    my $fileno = fileno($handle);

    $fileno_watcher[ $fileno ]->[ $mode ]->stop();
    
    EV_DEBUG && warn "loop_pause_filehandle( $handle ($fileno), $mode )\n";
}

sub loop_resume_filehandle {
    my ( $self, $handle, $mode ) = @_;

    my $fileno = fileno($handle);
    
    $fileno_watcher[ $fileno ]->[ $mode ]->start();
    
    EV_DEBUG && warn "loop_resume_filehandle( $handle ($fileno), $mode )\n";
}

sub _loop_filehandle_callback {
    my ( $watcher, $ev_mode ) = @_;
    
    EV_DEBUG && warn "_loop_filehandle_callback( " . $watcher->fh . ", $ev_mode )\n";

    my $mode = ( $ev_mode == EV::READ )
        ? MODE_RD
        : ( $ev_mode == EV::WRITE )
            ? MODE_WR
            : confess "Invalid mode occured in POE::Loop::EV IO callback: $ev_mode";

    # ->fh is actually the fileno, since that's what we called EV::io with
    $poe_kernel->_data_handle_enqueue_ready( $mode, $watcher->fh );
    
    $poe_kernel->_test_if_kernel_is_idle();
}

1;

__END__

=head1 NAME

POE::Loop::EV - a bridge that supports EV from POE

=head1 SYNOPSIS

    use POE 'Loop::EV';
    
    ...
    
    POE::Kernel->run();

=head1 DESCRIPTION

This class is an implementation of the abstract POE::Loop interface.
It follows POE::Loop's public interface exactly.  Therefore, please
see L<POE::Loop> for its documentation.

=head1 CAVEATS

Certain EV backends do not support polling on normal filehandles, namely
epoll and kqueue.  You should avoid using regular filehandles with select_read,
select_write, ReadWrite, etc.

See the L<libev documentation|http://pod.tst.eu/http://cvs.schmorp.de/libev/ev.pod#PORTABILITY_NOTES>
for more information on portability issues with different EV backends.

=head1 SEE ALSO

L<POE>, L<POE::Loop>, L<EV>

=head1 AUTHOR

Andy Grundman <andy@hybridized.org>

=head1 CONTRIBUTORS

=over

=item *

Dan Book <dbook@cpan.org>

=back

=head1 THANKS

Brandon Black, for his L<POE::Loop::Event_Lib> module.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by Andy Grundman.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
