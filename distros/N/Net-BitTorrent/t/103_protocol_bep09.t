use v5.42;
use lib 'lib';
use feature 'class';
use Test2::V1 -ipP;
no warnings;
use Net::BitTorrent::Protocol::BEP09;

class MockBEP09 : isa(Net::BitTorrent::Protocol::BEP09) {
    field $req_piece : reader : writer(set_req_piece);
    field $got_data  : reader : writer(set_got_data);
    ADJUST {
        $self->on( metadata_request => sub ( $self, $p ) { $self->set_req_piece($p) } );
        $self->on( metadata_data => sub ( $self, $p, $s, $d ) { $self->set_got_data( { piece => $p, size => $s, data => $d } ) } );
    }
}
subtest 'Metadata Messages' => sub {
    my $pwp = MockBEP09->new( infohash => 'A' x 20, peer_id => 'B' x 20, local_extensions => { ut_metadata => 3 } );
    $pwp->send_handshake();
    $pwp->receive_data( $pwp->write_buffer );    # Open

    # Fake extended handshake to set ut_metadata ID
    use Net::BitTorrent::Protocol::BEP03::Bencode qw[bencode];
    my $h_payload = bencode( { m => { ut_metadata => 3 } } );
    $pwp->receive_data( pack( 'N C C a*', length($h_payload) + 2, 20, 0, $h_payload ) );

    # Receive Request
    my $req_payload = bencode( { msg_type => 0, piece => 5 } );
    $pwp->receive_data( pack( 'N C C a*', length($req_payload) + 2, 20, 3, $req_payload ) );
    is $pwp->req_piece, 5, 'Received metadata request for piece 5';

    # Receive Data
    my $metadata_raw = 'SOME_METADATA_CHUNK';
    my $data_header  = bencode( { msg_type => 1, piece => 5, total_size => 1000 } );
    $pwp->receive_data( pack( 'N C C a*', length($data_header) + length($metadata_raw) + 2, 20, 3, $data_header . $metadata_raw ) );
    ok $pwp->got_data, 'Received metadata data';
    is $pwp->got_data->{piece}, 5,             'Piece index correct';
    is $pwp->got_data->{size},  1000,          'Total size correct';
    is $pwp->got_data->{data},  $metadata_raw, 'Raw data correct';
};
done_testing;
