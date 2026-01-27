use v5.40;
use lib 'lib', '../lib';
use Test2::V0;
use Net::BitTorrent::DHT;
use Net::BitTorrent::DHT::Security;
use Net::BitTorrent::Protocol::BEP03::Bencode qw[bencode bdecode];
#
subtest 'Token Management' => sub {
    my $sec   = Net::BitTorrent::DHT::Security->new();
    my $id    = $sec->generate_node_id('127.0.0.1');
    my $node  = Net::BitTorrent::DHT->new( node_id_bin => $id, port => 16881 );
    my $ip    = '1.2.3.4';
    my $token = $node->_generate_token($ip);
    ok $token, 'Generated a token';
    ok $node->_verify_token( $ip,        $token ), 'Verified token correctly';
    ok !$node->_verify_token( '5.6.7.8', $token ), 'Token failed for different IP';
};
subtest 'Announce Peer Flow' => sub {
    my $sec  = Net::BitTorrent::DHT::Security->new();
    my $id   = $sec->generate_node_id('127.0.0.1');
    my $node = Net::BitTorrent::DHT->new( node_id_bin => $id, port => 16882 );

    # Mock _send_raw to do nothing
    no warnings 'redefine';
    local *Net::BitTorrent::DHT::_send_raw = sub { };
    my $info_hash = pack( 'H*', 'deadbeef' x 5 );

    # 1. Simulate get_peers query to get a token
    my $ip    = '127.0.0.1';
    my $token = $node->_generate_token($ip);

    # 2. Simulate announce_peer query
    my $msg = {
        t => 'aa',
        y => 'q',
        q => 'announce_peer',
        a => { id => $sec->generate_node_id($ip), info_hash => $info_hash, port => 9999, token => $token }
    };

    # Manually trigger query handler (mocking the sender info)
    # _handle_query( $msg, $sender, $ip, $port )
    $node->_handle_query( $msg, undef, $ip, 12345 );

    # 3. Verify peer was stored
    my $peers = $node->peer_storage->get($info_hash);
    is scalar(@$peers),   1,    'One peer stored for info_hash';
    is $peers->[0]{ip},   $ip,  'Stored correct IP';
    is $peers->[0]{port}, 9999, 'Stored correct port';
};
#
done_testing;
