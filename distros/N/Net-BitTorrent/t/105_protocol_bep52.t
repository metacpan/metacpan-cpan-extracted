use v5.42;
use lib 'lib';
use Test2::V1 -ipP;
no warnings;
use Net::BitTorrent::Protocol::BEP52;
subtest 'v2 Handshake' => sub {
    my $ih  = 'A' x 32;
    my $id  = 'B' x 20;
    my $pwp = Net::BitTorrent::Protocol::BEP52->new( infohash => $ih, peer_id => $id );
    $pwp->send_handshake();
    my $out = $pwp->write_buffer;
    is length($out), 80, 'v2 Handshake length is 80';
    $pwp->receive_data($out);
    is $pwp->state, 'OPEN', 'v2 Handshake accepted';
};
subtest 'BEP 52 Messages' => sub {
    my $ih  = 'A' x 32;
    my $id  = 'B' x 20;
    my $pwp = Net::BitTorrent::Protocol::BEP52->new( infohash => $ih, peer_id => $id );
    $pwp->send_handshake();
    $pwp->receive_data( $pwp->write_buffer );
    my $root = 'R' x 32;
    $pwp->send_hash_request( $root, 3, 5, 0, 10 );
    my $out = $pwp->write_buffer;

    # length(4) + id(1) + root(32) + proof(1) + base(1) + index(4) + len(4) = 47
    is unpack( 'N',    $out ), 43, 'Hash request length prefix is 43';    # 1 + 32 + 1 + 1 + 4 + 4
    is unpack( 'x4 C', $out ), 21, 'Message ID 21 (HASH_REQUEST)';
};
done_testing;
