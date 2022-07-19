package Net::LibNFS::IO::Mojo;

use strict;
use warnings;

use Carp ();

use Net::LibNFS ();

my $REACTOR_BASE_CLASS = 'Mojo::Reactor';

use parent 'Net::LibNFS::IO::Contextual';

my $LOOP_BASE_CLASS = 'IO::Async::Loop';

sub start_io {
    my ($self) = @_;

    my $weak_self = $self;
    Scalar::Util::weaken($weak_self);

    $self->{'timer'} = $self->{'reactor'}->recurring(
        $self->_TIMER_INTERVAL(),
        sub {
            $weak_self && $weak_self->_service(0);
        },
    );

    $self->resume();

    $self->_poll_write_if_needed();

    return;
}

sub pause {
    my ($self) = @_;

    if ($self->{'_fh'}) {
        $self->{'_want_read'} = 0;
        $self->_sync_watch();
    }

    return;
}

sub resume {
    my ($self) = @_;

    $self->{'_want_read'} = 1;

    if (!$self->{'_fh'}) {
        $self->{'_fh'} = $self->_create_fh();

        my $weak_self = $self;
        Scalar::Util::weaken($weak_self);

        my $nfs = $self->_nfs();

        $self->{'reactor'}->io(
            $self->{'_fh'},
            sub {
                my $flags = 0;
                $flags |= Net::LibNFS::_POLLIN if $_[0];
                $flags |= Net::LibNFS::_POLLOUT if $_[1];

                $weak_self->_service($flags);

                return if !$weak_self->{'_want_write'};

                if (!($nfs->_which_events() & Net::LibNFS::_POLLOUT)) {
                    $weak_self->{'_want_write'} = 0;
                    $weak_self->_sync_watch();
                }
            },
        );
    }

    $self->_sync_watch();

    return;
}

#----------------------------------------------------------------------

sub _sync_watch {
    my ($self) = @_;

    # printf "FD %d: read? %d, write? %d\n", map { $_ // 0 } @{$self}{'_fh', '_want_read', '_want_write'};

    $self->{'reactor'}->watch(
        @{$self}{'_fh', '_want_read', '_want_write'},
    );
}

sub _PARSE_NEW_EXTRA {
    shift;  # class

    my $loop = shift || do {
        local ($@, $!);
        require Mojo::IOLoop;
        Mojo::IOLoop->singleton()->reactor();
    };

    local $@;
    if (!eval { $loop->isa($REACTOR_BASE_CLASS) }) {
        Carp::croak "Reactor object ($loop) isn’t a $REACTOR_BASE_CLASS instance!";
    }

    return (
        reactor => $loop,
    );
}

sub _CLONE_ARGS {
    return $_[0]{'reactor'};
}

sub _poll_write {
    my ($self) = @_;

    $self->{'_want_write'} = 1;
    $self->_sync_watch();
}

sub _stop {
    my ($self) = @_;

    if (my $timer = delete $self->{'timer'}) {
        $self->{'reactor'}->remove($timer);
    }

    if (my $fh = delete $self->{'_fh'}) {
        $self->{'reactor'}->remove($fh);
    }

    return;
}

1;
