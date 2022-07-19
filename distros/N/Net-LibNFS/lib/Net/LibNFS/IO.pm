package Net::LibNFS::IO;

use strict;
use warnings;

use parent 'Net::LibNFS::LeakDetector';

use Promise::XS ();

use Net::LibNFS::X ();

use constant {
    _DEBUG => 1,

    # Recommended in libnfs.h:
    _TIMER_INTERVAL => 0.1,
};

sub new {
    my ($class, $nfs, @extra) = @_;

    # Omit fd so we can use it as an indicator of whether
    # we’ve started polling or not.
    return bless {
        $class->_PARSE_NEW_EXTRA(@extra),
        nfs => $nfs,
        pid => $$,
    }, $class;
}

# ----------------------------------------------------------------------
# Subclass interface:

sub _PARSE_NEW_EXTRA { }

sub _CLONE_ARGS { }

sub _nfs { $_[0]{'nfs'} }

sub _fd { $_[0]{'nfs'}->_get_fd() }

# End subclass interface
#----------------------------------------------------------------------

#----------------------------------------------------------------------
# DESIGN NOTE: All _async_* functions accept a list of args, the last of
# which is a callback that runs when the request completes. The callback
# receives two args: the success payload, and the error. This module is
# where we translate that into a promise and its resolution or rejection.
#----------------------------------------------------------------------

sub clone {
    my ($self, $nfs) = @_;

    return (ref $self)->new($nfs, $self->_CLONE_ARGS());
}

sub act {
    my ($self, $nfs_ish, $funcname, @args) = @_;

    my $d = Promise::XS::deferred();

    my $deferreds_hr = $self->{'deferreds'} ||= {};

    my $ran;

    $nfs_ish->$funcname(@args, sub {

        # Sometimes this callback runs even in case of failure.
        return if $ran++;

        delete $deferreds_hr->{$d};

        if (my $err = $_[1]) {
            $d->reject($err);
        }
        else {
            $d->resolve($_[0]);
        }
    } );

    $deferreds_hr->{$d} = $d;

    $self->{'_io_started'} ||= do {
        $self->start_io();
        1;
    };

    return $d->promise();
}

#----------------------------------------------------------------------
# Protected:

sub _service {
    my ($self, $revents) = @_;

    if ( $self->{'service_err'} ||= $self->{'nfs'}->_service($revents) ) {
        $self->_stop();

        my $err = Net::LibNFS::X->create('BadConnection');
        $self->__reject_all($err);
    }
    else {
        $self->_poll_write_if_needed();
    }
}

sub _poll_write_if_needed {
    my ($self) = @_;

    if ($self->_nfs()->_which_events() & Net::LibNFS::_POLLOUT) {

        # In certain cases we end up with a POLLOUT request from
        # an NFS or RPC instance that is finished. When that happens
        # just ignore it.
        #
        $self->_poll_write() if $self->_fd() >= 0;
    }
}

#----------------------------------------------------------------------
# Privates:

sub __reject_all {
    my ($self, $err) = @_;

    $_->reject($err) for values %{ $self->{'deferreds'} };
    %{ $self->{'deferreds'} } = ();

    return;
}

1;
