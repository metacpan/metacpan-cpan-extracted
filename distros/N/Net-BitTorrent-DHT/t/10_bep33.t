use v5.40;
use lib 'lib', '../lib';
use Test2::V0;
use Net::BitTorrent::DHT;
use Net::BitTorrent::DHT::Security;
use Net::BitTorrent::Protocol::BEP03::Bencode qw[bdecode];
#
my $sec = Net::BitTorrent::DHT::Security->new();
my $id  = $sec->generate_node_id('127.0.0.1');
my $dht = Net::BitTorrent::DHT->new( node_id_bin => $id, bep33 => 1, port => 0 );

# Mock _send_raw to capture response
my $sent_data;
no warnings 'redefine';
local *Net::BitTorrent::DHT::_send_raw = sub {
    my ( $self, $data, $dest ) = @_;
    $sent_data = $data;
};
use warnings 'redefine';
my $info_hash = pack( 'H*', '12' x 20 );

# 1. Test announce_peer with seed flag
my $token = $dht->_generate_token('127.0.0.1');

# Announce a seeder
$dht->_handle_query(
    {   t => 'a1',
        y => 'q',
        q => 'announce_peer',
        a => { id => $sec->generate_node_id('127.0.0.1'), info_hash => $info_hash, port => 1111, token => $token, seed => 1 }
    },
    'dummy',
    '127.0.0.1',
    1111
);

# Announce a leecher
$dht->_handle_query(
    {   t => 'a2',
        y => 'q',
        q => 'announce_peer',
        a => {
            id        => $sec->generate_node_id('127.0.0.2'),
            info_hash => $info_hash,
            port      => 2222,
            token     => $dht->_generate_token('127.0.0.2'),

            # seed omitted
        }
    },
    'dummy',
    '127.0.0.2',
    2222
);
my $peers = $dht->peer_storage->get($info_hash);
is scalar(@$peers),                       2, 'Stored 2 peers';
is scalar( grep { $_->{seed} } @$peers ), 1, 'One is a seeder';

# 2. Test scrape_peers query
$sent_data = undef;
$dht->_handle_query( { t => 'sp1', y => 'q', q => 'scrape_peers', a => { id => $sec->generate_node_id('1.2.3.4'), info_hash => $info_hash } },
    'dummy', '1.2.3.4', 1234 );
my $res = bdecode($sent_data);
is $res->{r}{sn}, 1, 'Scrape response has 1 seeder';
is $res->{r}{ln}, 1, 'Scrape response has 1 leecher';

# 3. Test scrape_peers response handling
my ( $nodes, $found_peers, $scrape )
    = $dht->_handle_response( { t => 'sp', y => 'r', r => { id => $sec->generate_node_id('5.6.7.8'), sn => 10, ln => 20 } }, 'dummy', '5.6.7.8',
    5678 );
ok $scrape, 'Handled scrape response';
is $scrape->{sn}, 10, 'Correct seeder count from response';
is $scrape->{ln}, 20, 'Correct leecher count from response';
#
done_testing;
