package Net::LibNFS::IO::AnyEvent;

use strict;
use warnings;

use AnyEvent;
use Scalar::Util;

use Net::LibNFS;
use Net::LibNFS::X;

use parent 'Net::LibNFS::IO';

sub pause {
    delete $_[0]{'read_w'};
    return $_[0];
}

sub resume {
    my ($self) = @_;

    my $watch_sr = \$self->{'watches'}{'read'};

    if (!$$watch_sr) {
        my $weak_self = $self;
        Scalar::Util::weaken($weak_self);

        $$watch_sr = AnyEvent->io(
            poll => 'r',
            fh => $self->_fd(),
            cb => sub {
                $weak_self->_service(Net::LibNFS::_POLLIN);
            },
        )
    };

    return $self;
}

sub start_io {
    my ($self) = @_;

    my $weak_self = $self;
    Scalar::Util::weaken($weak_self);

    $self->{'watches'} = {
        timer => AnyEvent->timer(
            after => $self->_TIMER_INTERVAL(),
            interval => $self->_TIMER_INTERVAL(),
            cb => sub {
                $weak_self->_service(0);
            },
        ),
    };

    $self->resume();

    $self->_poll_write_if_needed();

    return;
}

#----------------------------------------------------------------------

sub _stop {
    my ($self) = @_;

    %{ $self->{'watches'} } = ();

    return;
}

sub _poll_write {
    my ($self) = @_;

    $self->{'watches'}{'write'} ||= do {
        my $fd = $self->_fd();

        my $nfs = $self->_nfs();

        my $weak_self = $self;
        Scalar::Util::weaken($weak_self);

        AnyEvent->io(
            poll => 'w',
            fh => $fd,
            cb => sub {
                $weak_self->_service(Net::LibNFS::_POLLOUT);

                if (!($nfs->_which_events() & Net::LibNFS::_POLLOUT)) {
                    undef $weak_self->{'watches'}{'write'};
                }
            },
        );
    };

    return;
}

1;
