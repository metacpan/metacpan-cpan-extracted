use v5.40;
use lib 'lib';
use Test::More;
use Net::BitTorrent::DHT;
use Net::BitTorrent::Protocol::BEP03::Bencode qw[bencode bdecode];
use Socket                                    qw[pack_sockaddr_in inet_aton];
#
my $node_id = pack( 'H*', '1' x 40 );
my $dht     = Net::BitTorrent::DHT->new(
    node_id_bin => $node_id,
    port        => 0,          # Random port
    bep42       => 0,          # Disable security for testing
    ssrf_bypass => 1
);
subtest 'Outgoing sample_infohashes' => sub {
    my $target = pack( 'H*', '2' x 40 );
    my $addr   = '127.0.0.1';
    my $port   = 12345;
    ok( $dht->can('sample_infohashes_remote'), 'Method sample_infohashes_remote exists' );
    ok( $dht->can('sample'),                   'High-level sample method exists' );
    $dht->sample_infohashes_remote( $target, $addr, $port );
    pass('sample_infohashes_remote called without crash');
};
subtest 'Incoming sample_infohashes query' => sub {
    my $query_id  = pack( 'H*', '3' x 40 );
    my $target    = pack( 'H*', '4' x 40 );
    my $query     = { t => 'si', y => 'q', q => 'sample_infohashes', a => { id => $query_id, target => $target, } };
    my $infohash1 = pack( 'H*', 'a' x 40 );
    my $infohash2 = pack( 'H*', 'b' x 40 );
    $dht->peer_storage->put( $infohash1, [ { ip => '1.1.1.1', port => 1 } ] );
    $dht->peer_storage->put( $infohash2, [ { ip => '2.2.2.2', port => 2 } ] );
    my $sender        = pack_sockaddr_in( 6881, inet_aton('127.0.0.2') );
    my $response_node = $dht->_handle_query( $query, $sender, '127.0.0.2', 6881 );
    ok( $response_node, 'Got response node info' );
    is( $response_node->{id}, $query_id, 'Responding to correct node ID' );
};
subtest 'Handling sample_infohashes response' => sub {
    my $resp_id = pack( 'H*', '5' x 40 );
    my $sample1 = pack( 'H*', 'c' x 40 );
    my $sample2 = pack( 'H*', 'd' x 40 );

    # Initiate a query to populate _pending_queries
    my $sent_data;
    no warnings 'redefine';
    local *Net::BitTorrent::DHT::_send_raw = sub {
        my ( $self, $data, $dest ) = @_;
        $sent_data = bdecode($data);
    };
    $dht->sample_infohashes_remote( pack( 'H*', '6' x 40 ), '127.0.0.3', 9999 );
    my $tid = $sent_data->{t};
    my $msg = { t => $tid, y => 'r', r => { id => $resp_id, samples => $sample1 . $sample2, num => 2, interval => 3600, } };
    my ( $nodes, $peers, $data ) = $dht->_handle_response( $msg, undef, '127.0.0.3', 9999 );
    ok( $data, 'Data returned from response handler' );
    is( $data->{id}, $resp_id, 'ID matches' );
    is_deeply( $data->{samples}, [ $sample1, $sample2 ], 'Samples extracted correctly' );
    is( $data->{num},      2,    'Num matches' );
    is( $data->{interval}, 3600, 'Interval matches' );
};
subtest 'BEP 51 toggle' => sub {
    my $dht_off  = Net::BitTorrent::DHT->new( node_id_bin => $node_id, port => 0, bep51 => 0, bep42 => 0, );
    my $query_id = pack( 'H*', '3' x 40 );
    my $target   = pack( 'H*', '4' x 40 );
    my $query    = { t => 'si', y => 'q', q => 'sample_infohashes', a => { id => $query_id, target => $target, } };

    # We need to capture the response sent via _send_raw
    my $sent_data;
    no warnings 'redefine';
    local *Net::BitTorrent::DHT::_send_raw = sub {
        my ( $self, $data, $dest ) = @_;
        $sent_data = bdecode($data);
    };
    my $sender = pack_sockaddr_in( 6881, inet_aton('127.0.0.2') );
    $dht_off->_handle_query( $query, $sender, '127.0.0.2', 6881 );
    ok( $sent_data,                       'Sent a response' );
    ok( !exists $sent_data->{r}{samples}, 'No samples in response when bep51 is off' );
};
done_testing;
