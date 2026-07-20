use v5.42;
use lib 'lib';
use feature 'class';
use Test2::V1 -ipP;
no warnings;
use Net::BitTorrent::Protocol::BEP10;

class MockBEP10 : isa(Net::BitTorrent::Protocol::BEP10) {
    field $got_handshake : reader : writer(set_got_handshake);
    ADJUST {
        $self->set_reserved_bit( 5, 0x10 );
        $self->on( ext_handshake => sub ( $self, $data ) { $self->set_got_handshake($data) } );
    }
}
subtest 'Reserved Bit' => sub {
    my $ih  = 'A' x 20;
    my $id  = 'B' x 20;
    my $pwp = MockBEP10->new( infohash => $ih, peer_id => $id );
    my $res = $pwp->reserved;
    ok ord( substr( $res, 5, 1 ) ) & 0x10, 'Extension protocol bit set in reserved bytes';
};
subtest 'Extended Handshake' => sub {
    my $ih  = 'A' x 20;
    my $id  = 'B' x 20;
    my $pwp = MockBEP10->new( infohash => $ih, peer_id => $id, local_extensions => { ut_pex => 1 } );

    # Open the connection
    $pwp->send_handshake();
    $pwp->receive_data( $pwp->write_buffer );
    use Net::BitTorrent::Protocol::BEP03::Bencode qw[bencode];
    my $payload = bencode( { m => { ut_pex => 2 }, v => 'Test Client' } );
    my $msg     = pack( 'N C C a*', length($payload) + 2, 20, 0, $payload );
    $pwp->receive_data($msg);
    my $h = $pwp->got_handshake;
    ok $h, 'Received extended handshake';
    is $h->{m}{ut_pex}, 2,             'Parsed remote extensions';
    is $h->{v},         'Test Client', 'Parsed remote version';
};
done_testing;
