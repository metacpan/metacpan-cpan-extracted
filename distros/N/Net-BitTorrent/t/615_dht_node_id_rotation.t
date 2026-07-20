use v5.40;
use Test2::V0;
use lib 'lib', '../lib';
use Net::BitTorrent::DHT;
use Net::BitTorrent::Protocol::BEP03::Bencode qw[bencode];
use Socket                                    qw[pack_sockaddr_in inet_aton];
#
my $node_id = pack( 'H*', '1' x 40 );
my $dht     = Net::BitTorrent::DHT->new(
    node_id_bin => $node_id,
    port        => 0,          # Random port
    bep42       => 1           # Enabled for testing rotation
);
my $old_id = $dht->node_id_bin;

# Simulate receiving DHT responses from 5 different "nodes" reporting a new external IP
my $new_ip_bin = pack( 'C4', 8, 8, 8, 8 );    # 8.8.8.8

# Each source IP gets one vote, so we need 5 distinct source IPs (all public)
my @src_ips = ( '1.2.3.4', '198.51.100.1', '198.51.100.2', '203.0.113.1', '203.0.113.2' );
for my $src_ip (@src_ips) {
    my $addr     = pack_sockaddr_in( 6881, inet_aton($src_ip) );
    my $response = bencode( { t => 'aa', y => 'r', r => { id => "NODE" . $src_ip . ( "0" x 10 ) }, ip => $new_ip_bin } );
    $dht->handle_incoming( $response, $addr );
}
my $new_id = $dht->node_id_bin;
isnt $new_id, $old_id, 'node_id was rotated after consensus';
$dht->set_node_id('afdsafdsa');

# Verify the new ID is valid for the detected IP
use Net::BitTorrent::DHT::Security;
my $sec = Net::BitTorrent::DHT::Security->new();
ok $sec->validate_node_id( $new_id, '8.8.8.8' ), "New node_id is valid for 8.8.8.8";
#
done_testing;
