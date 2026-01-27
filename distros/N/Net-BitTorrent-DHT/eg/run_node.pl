use v5.40;
use lib '../lib';
use Net::BitTorrent::DHT;
use Net::BitTorrent::DHT::Security;
$|++;

# Generate a valid BEP 42 Node ID
my $sec = Net::BitTorrent::DHT::Security->new();
my $id  = $sec->generate_node_id('127.0.0.1');                                                # Default for local testing
my $dht = Net::BitTorrent::DHT->new( node_id_bin => $id, port => 6881 + int( rand(100) ) );
say '[INFO] Starting DHT node on port ' . $dht->port . '...';
say '[INFO] Node ID: ' . unpack( 'H*', $id );

# This will enter an infinite loop
$dht->run();
