package Net::Curl::Promiser::Backend::AnyEvent;

use strict;
use warnings;

use parent 'Net::Curl::Promiser::Backend::LoopBase';

use Net::Curl::Multi ();

use AnyEvent;

#----------------------------------------------------------------------

sub _io {
    my ($self, $fd, $multi, $direction, $action_num) = @_;

    $self->{'_watches'}{$fd}{$direction} = AnyEvent->io(
        fh => $fd,
        poll => $direction,
        cb => sub {
            $self->process($multi, [$fd, $action_num]);
        },
    );

    return;
}

sub SET_TIMER {
    my ($self, $multi, $timeout_ms) = @_;

    $self->{timer} = AnyEvent->timer(
        after => $timeout_ms / 1000,
        cb => sub {
            $self->time_out($multi);
        },
    );
}

sub CLEAR_TIMER { $_[0]->{'timer'} = undef }

sub SET_POLL_IN {
    my ($self, $fd, $multi) = @_;

    $self->_io( $fd, $multi, 'r', Net::Curl::Multi::CURL_CSELECT_IN() );

    delete $self->{'_watches'}{$fd}{'w'};

    return;
}

sub SET_POLL_OUT {
    my ($self, $fd, $multi) = @_;

    $self->_io( $fd, $multi, 'w', Net::Curl::Multi::CURL_CSELECT_OUT() );

    delete $self->{'_watches'}{$fd}{'r'};

    return;
}

sub SET_POLL_INOUT {
    my ($self, $fd, $multi) = @_;

    $self->_io( $fd, $multi, 'r', Net::Curl::Multi::CURL_CSELECT_IN() );
    $self->_io( $fd, $multi, 'w', Net::Curl::Multi::CURL_CSELECT_OUT() );

    return;
}

sub STOP_POLL {
    my ($self, $fd) = @_;

    delete $self->{'_watches'}{$fd};

    return;
}

1;
