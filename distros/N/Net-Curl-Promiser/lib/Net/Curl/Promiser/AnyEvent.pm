package Net::Curl::Promiser::AnyEvent;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Net::Curl::Promiser::AnyEvent

=head1 SYNOPSIS

    my $promiser = Net::Curl::Promiser::AnyEvent->new();

    my $cv = AnyEvent->condvar();

    my $handle = Net::Curl::Easy->new();
    $handle->setopt( CURLOPT_URL() => $url );

    $promiser->add_handle($handle)->then(
        sub { print "$url completed.$/" },
        sub { warn "$url failed: " . shift },
    )->finally($cv);

    $cv->recv();

=head1 DESCRIPTION

This module provides an L<AnyEvent>-compatible interface for
L<Net::Curl::Promiser>.

See F</examples> in the distribution for a fleshed-out demonstration.

=head1 INVALID METHODS

The following methods from L<Net::Curl::Promiser> are unneeded in this
class and thus produce an exception if called:

=over

=item C<process()>

=item C<time_out()>

=item C<get_timeout()>

=back

=cut

#----------------------------------------------------------------------

use parent 'Net::Curl::Promiser';

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
        $self->SUPER::time_out();
    };

    if ($timeout_ms < 0) {
        if ($multi->handles()) {
            $self->{'timer'} = AnyEvent->timer(
                after => 5,
                interval => 5,
                cb => $cb,
            );
        }
        else {
            delete $self->{'timer'};
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

sub process { die 'Unneeded method: ' . (caller 0)[3] };
sub get_timeout { die 'Unneeded method: ' . (caller 0)[3] };
sub time_out { die 'Unneeded method: ' . (caller 0)[3] };

sub _GET_FD_ACTION {
    my ($self, $args_ar) = @_;

    return +{ @$args_ar };
}

sub _io {
    my ($self, $fd, $direction, $action_num) = @_;

    $self->{'_watches'}{$fd}{$direction} = AnyEvent->io(
        fh => $fd,
        poll => $direction,
        cb => sub {
            $self->SUPER::process($fd, $action_num);
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
