package Net::LibNFS::IO::IOAsync;

use strict;
use warnings;

use Carp ();
use Scalar::Util ();

use Net::LibNFS;
use Net::LibNFS::X;

use IO::Async::Handle ();
use IO::Async::Timer::Periodic ();

use parent 'Net::LibNFS::IO::Contextual';

my $LOOP_BASE_CLASS = 'IO::Async::Loop';

sub start_io {
    my ($self) = @_;

    my $weak_self = $self;
    Scalar::Util::weaken($weak_self);

    $self->{'timer'} = IO::Async::Timer::Periodic->new(
        interval => $self->_TIMER_INTERVAL(),
        on_tick => sub {
            $weak_self && $weak_self->_service(0);
        },
    );

    $self->{'timer'}->start();

    $self->{'loop'}->add( $self->{'timer'} );

    $self->resume();

    $self->_poll_write_if_needed();

    return;
}

sub pause {
    my ($self) = @_;

    if (my $reader = $self->{'io_handle'}) {
        $reader->want_readready(0);
    }

    return;
}

sub resume {
    my ($self) = @_;

    if (my $reader = $self->{'io_handle'}) {
        $reader->want_readready(1);
    }
    else {
        my $fh = $self->_create_fh();

        my $weak_self = $self;
        Scalar::Util::weaken($weak_self);

        my $nfs = $self->_nfs();

        my $notifier = IO::Async::Handle->new(
            handle => $fh,

            want_readready => 1,

            on_read_ready => sub {
                $weak_self && $weak_self->_service(Net::LibNFS::_POLLIN);
            },

            on_write_ready => sub {
                $weak_self->_service(Net::LibNFS::_POLLOUT);

                if (!($nfs->_which_events() & Net::LibNFS::_POLLOUT)) {
                    shift()->want_writeready(0);
                }
            },
        );

        $self->{'loop'}->add($notifier);

        $self->{'io_handle'} = $notifier;
    }

    return;
}

#----------------------------------------------------------------------

sub _PARSE_NEW_EXTRA {
    shift;  # class

    my $loop = shift or Carp::croak "Need loop object!";

    local $@;
    if (!eval { $loop->isa($LOOP_BASE_CLASS) }) {
        Carp::croak "Loop object ($loop) isn’t an $LOOP_BASE_CLASS instance!";
    }

    return (
        loop => $loop,
    );
}

sub _CLONE_ARGS {
    return $_[0]{'loop'};
}

sub _poll_write {
    $_[0]{'io_handle'}->want_writeready(1);
}

sub _stop {
    my ($self) = @_;

    if (my $timer = delete $self->{'timer'}) {
        $timer->stop();
        $self->{'loop'}->remove($timer);
    }

    if (my $reader = delete $self->{'io_handle'}) {
        $self->{'loop'}->remove($reader);
    }

    return;
}

1;
