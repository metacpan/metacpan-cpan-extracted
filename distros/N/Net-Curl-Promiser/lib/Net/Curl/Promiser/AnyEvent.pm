package Net::Curl::Promiser::AnyEvent;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Net::Curl::Promiser::AnyEvent - support for L<AnyEvent>

=head1 SYNOPSIS

    my $promiser = Net::Curl::Promiser::AnyEvent->new();

    my $handle = Net::Curl::Easy->new();
    $handle->setopt( CURLOPT_URL() => $url );

    my $cv = AnyEvent->condvar();

    $promiser->add_handle($handle)->then(
        sub { print "$url completed.$/" },
        sub { warn "$url failed: " . shift },
    )->finally($cv);

    $cv->recv();

=head1 DESCRIPTION

This module provides an L<AnyEvent>-compatible interface for
L<Net::Curl::Promiser>.

See F</examples> in the distribution for a fleshed-out demonstration.

B<NOTE:> The actual interface is that provided by
L<Net::Curl::Promiser::LoopBase>.

=cut

#----------------------------------------------------------------------

use parent 'Net::Curl::Promiser::LoopBase';

use Net::Curl::Multi ();

use AnyEvent;

#----------------------------------------------------------------------

sub _INIT {
    my ($self, $args_ar) = @_;

    $self->{'_watches'} = {};

    $self->setopt( Net::Curl::Multi::CURLMOPT_TIMERFUNCTION(), \&_cb_timer );
    $self->setopt( Net::Curl::Multi::CURLMOPT_TIMERDATA(), $self );

    return;
}

sub _cb_timer {
    my ($multi, $timeout_ms, $self) = @_;

    my $cb = sub {
        $self->_time_out_in_loop();
    };

    delete $self->{'timer'};

    if ($timeout_ms < 0) {
        if ($multi->handles()) {
            $self->{'timer'} = AnyEvent->timer(
                after => 5,
                interval => 5,
                cb => $cb,
            );
        }
    }
    else {
        $self->{timer} = AnyEvent->timer(
            after => $timeout_ms / 1000,
            cb => $cb,
        );
    }

    return 1;
}

sub _io {
    my ($self, $fd, $direction, $action_num) = @_;

    $self->{'_watches'}{$fd}{$direction} = AnyEvent->io(
        fh => $fd,
        poll => $direction,
        cb => sub {
            $self->_process_in_loop($fd, $action_num);
        },
    );

    return;
}

sub _SET_POLL_IN {
    my ($self, $fd) = @_;

    $self->_io( $fd, 'r', Net::Curl::Multi::CURL_CSELECT_IN() );

    delete $self->{'_watches'}{$fd}{'w'};

    return;
}

sub _SET_POLL_OUT {
    my ($self, $fd) = @_;

    $self->_io( $fd, 'w', Net::Curl::Multi::CURL_CSELECT_OUT() );

    delete $self->{'_watches'}{$fd}{'r'};

    return;
}

sub _SET_POLL_INOUT {
    my ($self, $fd) = @_;

    $self->_io( $fd, 'r', Net::Curl::Multi::CURL_CSELECT_IN() );
    $self->_io( $fd, 'w', Net::Curl::Multi::CURL_CSELECT_OUT() );

    return;
}

sub _STOP_POLL {
    my ($self, $fd) = @_;

    delete $self->{'_watches'}{$fd};

    return;
}

1;
