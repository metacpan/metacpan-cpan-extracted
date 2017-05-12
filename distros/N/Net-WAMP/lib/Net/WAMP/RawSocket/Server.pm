package Net::WAMP::RawSocket::Server;

use strict;
use warnings;

use parent 'Net::WAMP::RawSocket';

use Net::WAMP::RawSocket::Constants ();

sub receive_and_answer_handshake {
    my ($self) = @_;

    if ($self->{'_received_handshake'}) {
        die "Already!"; #XXX
    }

    my ($octet2, $ser_name, $serializer_code) = $self->_get_and_unpack_handshake_header();

    if (length $octet2) {
        $self->{'_received_handshake'} = 1;

        $self->{'_serialization'} = $ser_name;

        my $max_len_code = $self->{'_max_receive_code'};

        $self->_send_bytes(
            pack(
                'C4',
                Net::WAMP::RawSocket::Constants::MAGIC_FIRST_OCTET(),
                ($max_len_code << 4) | $serializer_code,
                0, 0,   #reserved
            ),
            sub {
#print STDERR "handshake DONE\n";
                $self->_set_handshake_done();
            },
        );

        return 1;

        #This function shouldn’t be called anymore unless the client
        #for some reason sends more data to be read before we get a
        #chance to write.
    }

    return undef;
}

1;
