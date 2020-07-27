package Net::Curl::Promiser::Backend::Mojo;

use strict;
use warnings;

use parent 'Net::Curl::Promiser::Backend::LoopBase';

use Net::Curl::Multi ();

use Mojo::IOLoop ();
use Mojo::Promise ();

use Net::Curl::Promiser::FDFHStore ();

use constant PROMISE_CLASS => 'Mojo::Promise';

sub new {
    my ($class, $loop) = @_;

    my $self = $class->SUPER::new();

    $self->{'_fhstore'} = Net::Curl::Promiser::FDFHStore->new();

    return $self;
}

#----------------------------------------------------------------------

sub SET_TIMER {
    my ($self, $multi, $timeout_ms) = @_;

    $self->{onetimer} = Mojo::IOLoop->timer(
        $timeout_ms / 1000,
        sub {
            $self->time_out($multi);
        },
    );
}

sub CLEAR_TIMER {
    my ($ot) = delete $_[0]->{'onetimer'};
    Mojo::IOLoop->remove($ot) if $ot;
}

sub _io {
    my ($self, $fd, $multi, $read_yn, $write_yn) = @_;

    my $socket = $self->{'_watched_sockets'}{$fd} ||= do {
        my $s = $self->{'_fhstore'}->get_fh($fd);

        Mojo::IOLoop->singleton->reactor->io(
            $s,
            sub {
                $self->process(
                    $multi,
                    [ $fd, $_[1] ? Net::Curl::Multi::CURL_CSELECT_OUT() : Net::Curl::Multi::CURL_CSELECT_IN() ],
                );
            },
        );

        $s;
    };

    Mojo::IOLoop->singleton->reactor->watch(
        $socket,
        $read_yn,
        $write_yn,
    );

    return;
}

sub SET_POLL_IN {
    my ($self, $fd, $multi) = @_;

    $self->_io( $fd, $multi, 1, 0 );

    return;
}

sub SET_POLL_OUT {
    my ($self, $fd, $multi) = @_;

    $self->_io( $fd, $multi, 0, 1 );

    return;
}

sub SET_POLL_INOUT {
    my ($self, $fd, $multi) = @_;

    $self->_io( $fd, $multi, 1, 1 );

    return;
}

sub STOP_POLL {
    my ($self, $fd) = @_;

    if (my $socket = delete $self->{'_watched_sockets'}{$fd}) {
        Mojo::IOLoop->remove($socket);
    }

    return;
}

1;
