use v5.40;
use lib 'lib';
use Test2::V1 -ipP;
no warnings;
use Net::BitTorrent::Tracker::UDP;
use Config;
use constant HAS_64BIT => $Config{ivsize} >= 8;
subtest 'UDP Packet Building' => sub {
    my $tracker = Net::BitTorrent::Tracker::UDP->new( url => 'udp://127.0.0.1:6881', ssrf_bypass => 1 );
    my ( $tid, $conn_req ) = $tracker->build_connect_packet();
    is length($conn_req), 16, 'Connect packet is 16 bytes';
    my $cid      = HAS_64BIT ? 0x12345678 : pack( 'NN', 0, 0x12345678 );
    my $tmpl     = HAS_64BIT ? 'N N Q>'   : 'N N a8';
    my $conn_res = pack( $tmpl, 0, $tid, $cid );

    # Refined test:
    my $ann_req = $tracker->build_announce_packet( { info_hash => 'A' x 20, peer_id => 'B' x 20, port => 6881 } );
    ok $ann_req, 'Announce packet built';
    is length($ann_req), 98, 'Announce packet is 98 bytes';
};
#
subtest 'parse_announce_response caps peer list at 500' => sub {
    my $tracker = Net::BitTorrent::Tracker::UDP->new( url => 'udp://tracker.example.com:8080/announce', ssrf_bypass => 1 );

    # Build an announce response with 600 IPv4 peers (600 * 6 = 3600 bytes after header)
    my $header    = pack( 'N N N N N', 1, 12345, 1800, 50, 10 );    # action=1, tid, interval, leechers, seeders
    my $peer_data = '';
    for my $i ( 1 .. 600 ) {
        $peer_data .= pack( 'C4 n', 10, 0, int( $i / 256 ), $i % 256, 6881 );
    }
    my $response = $tracker->parse_announce_response( $header . $peer_data );
    ok scalar @{ $response->{peers} } <= 500, 'peer list capped at 500 (got ' . scalar @{ $response->{peers} } . ')';
    is $response->{interval}, 1800, 'interval still parsed correctly';
    is $response->{seeders},  10,   'seeders still parsed correctly';
};
#
subtest 'parse_scrape_response bounds by actual data' => sub {
    my $udp    = Net::BitTorrent::Tracker::UDP->new( url => 'udp://127.0.0.1:6881' );
    my $data   = pack( 'N N', 2, 12345 ) . pack( 'N N N', 10, 50, 8 );
    my $result = $udp->parse_scrape_response( $data, 5 );
    is scalar @{ $result->{files} }, 1,  'scrape limited to actual data (1 entry not 5)';
    is $result->{files}[0]{seeders}, 10, 'seeders parsed correctly';
};
#
done_testing;
