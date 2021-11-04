package Net::Libwebsockets::Loop::IOAsync;

use strict;
use warnings;

use parent 'Net::Libwebsockets::Loop';

use POSIX ();

use feature 'current_sub';

use Net::Libwebsockets ();

use IO::Async::Handle ();

sub new {
    my ($class, $loop) = @_;

    return bless {
        pid => $$,
        loop => $loop,
    }, $class;
}

sub _do_later {
    $_[0]->{'loop'}->later( $_[1] );

    # return omitted to save an op
}

sub _create_set_timer_cr {
    my ($self) = @_;

    my $loop = $self->{'loop'};

    my $ctx = $self->{'lws_context'};

    my $timer_sr = \$self->{'timer'};

    return sub {
        $loop->unwatch_time($$timer_sr) if $$timer_sr;

        $$timer_sr = $loop->watch_time(
            after => Net::Libwebsockets::_get_timeout($ctx) / 1000,
            code => __SUB__,
        );
    };
}

sub add_fd {
    my ($self, $fd) = @_;

    my $perl_fd = POSIX::dup($fd) or die "dup(FD $fd): $!";

    open( my $fh, '+<&=', $perl_fd ) or die "open(FD $perl_fd): $!";

    my $ctx = $self->{'lws_context'};

    my $set_timer_cr = $self->_get_set_timer_cr();

    $self->{'fd_handle'}{$fd} = IO::Async::Handle->new(
        handle => $fh,
        on_read_ready => sub {
            Net::Libwebsockets::_lws_service_fd_read($ctx, $fd);
            &$set_timer_cr;
        },
        on_write_ready => sub {
            Net::Libwebsockets::_lws_service_fd_write($ctx, $fd);
            &$set_timer_cr;
        },

        want_readready => 1,
        want_writeready => 0,
    );

    $self->{'loop'}->add( $self->{'fd_handle'}{$fd} );

    # return omitted to save an op
}

sub add_to_fd {
    # my ($self, $fd, $flags) = @_;

    my $handle = $_[0]->{'fd_handle'}{$_[1]} or do {
        die "Can’t add polling ($_[2]) to FD ($_[1]) that isn’t added!";
    };

    if ($_[2] & Net::Libwebsockets::_LWS_EV_READ) {
        $handle->want_readready(1);
    }

    if ($_[2] & Net::Libwebsockets::_LWS_EV_WRITE) {
        $handle->want_writeready(1);
    }

    # return omitted to save an op
}

sub remove_from_fd {
    # my ($self, $fd, $flags) = @_;

    if (my $handle = $_[0]->{'fd_handle'}{$_[1]}) {
        if ($_[2] & Net::Libwebsockets::_LWS_EV_READ) {
            $handle->want_readready(0);
        }

        if ($_[2] & Net::Libwebsockets::_LWS_EV_WRITE) {
            $handle->want_writeready(0);
        }
    }
    else {
        # warn "removing poll $flags from non-polled FD $fd";
    }

    # return omitted to save an op
}

sub remove_fd {
    my ($self, $fd) = @_;

    if (my $handle = delete $self->{'fd_handle'}{$fd}) {
        $self->{'loop'}->remove($handle);
    }
    else {
        # warn "LWS wants to remove non-polled FD $fd";
    }

    # return omitted to save an op
}

sub _clear_timer {
    my ($self) = @_;

    if ($self->{'timer'}) {
        $self->{'loop'}->unwatch_time($self->{'timer'});
        undef $self->{'timer'};
    }
}

1;
