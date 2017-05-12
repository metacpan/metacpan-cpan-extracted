package Net::WAMP::RawSocket::Client;

use strict;
use warnings;

use parent 'Net::WAMP::RawSocket';

use Net::WAMP::RawSocket::Constants ();
use Net::WAMP::X ();

sub new {
    my ($class, @args) = @_;

    my $self = $class->SUPER::new(@args);

    return $self;
}

sub send_handshake {
    my ($self, %opts) = @_;

    $self->{'_serialization'} = $opts{'serialization'} || Net::WAMP::RawSocket::Constants::DEFAULT_SERIALIZATION();

    if ($self->{'_enqueued_handshake'}) {
        die "Already!"; #XXX
    }

    $self->{'_enqueued_handshake'} = 1;

    $self->_send_bytes(
        $self->_create_client_handshake(
            $self->{'_serialization'},
        ),
    );

    return;
}

sub verify_handshake {
    my ($self) = @_;

    my ($octet2, $ser_name, $resp_serializer_code) = $self->_get_and_unpack_handshake_header();

    #States D and E exit here; only continue if got the full header.
    if (defined $octet2) {
        if ( !$resp_serializer_code ) {
            my $err_code = $octet2 >> 4;
            my $err_str = $self->can("HANDSHAKE_ERR_$err_code");
            $err_str = $err_str ? '[' . $err_str->() . ']' : q<>;

            die "Handshake error: [$err_code]$err_str\n"
        }

        #I wonder why the client and router have to use the same serializer??
        if ( $resp_serializer_code != $self->{'_rs_serialization_code'} ) {
            die "Protocol error: response serializer ($resp_serializer_code) != sent ($self->{'_rs_serialization_code'})\n";
        }

        $self->_set_handshake_done();

        return 1;
    }

    return undef;
}

sub _create_client_handshake {
    my ($self, $serialization) = @_;

    my $serialization_code = Net::WAMP::RawSocket::Constants::get_serialization_code($serialization);

    #Might as well save it for later
    $self->{'_rs_serialization_code'} = $serialization_code;

    return pack(
        'C*',
        Net::WAMP::RawSocket::Constants::MAGIC_FIRST_OCTET(),
        ($self->{'_max_receive_code'} << 4) + $serialization_code,
        0, 0,   #reserved
    );
}

1;
