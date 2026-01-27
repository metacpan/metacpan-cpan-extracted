use v5.40;
use lib '../lib';
use Net::BitTorrent::DHT;
use Net::BitTorrent::DHT::Security;
use Digest::SHA qw[sha1];
$|++;

# This script demonstrates BEP 51: DHT Infohash Indexing.
# It queries a node for a sample of the info-hashes it is tracking.
my $sec = Net::BitTorrent::DHT::Security->new();
my $id  = $sec->generate_node_id('127.0.0.1');
my $dht = Net::BitTorrent::DHT->new( node_id_bin => $id, port => 6881 + int( rand(100) ), debug => 1 );

# Populate local storage so we can query ourselves for the demo
for ( 1 .. 5 ) {
    $dht->peer_storage->put( sha1("fake torrent $_"), [ { ip => '127.0.0.1', port => 1234 } ] );
}
say "[INFO] Starting DHT node on port " . $dht->port . "...";
say "[INFO] Sending sample_infohashes query to ourselves...";

# In a real scenario, you'd send this to a remote node.
# Here we use the target ID of the node we're querying or a random one to get a sample.
my $target = sha1("some target");
$dht->sample_infohashes_remote( $target, '127.0.0.1', $dht->port );

# Since we're querying ourselves on the same socket, we need to process the packets.
# handle_incoming will process the query we just sent to ourselves.
$dht->handle_incoming();

# Now we need to process the response we (theoretically) sent.
# But since handle_incoming calls _send_raw, and we haven't mocked it to loop back,
# this demo is mostly showing how to call the method.
# If we were using a real network and a remote node:
# my ($nodes, $peers, $data) = $dht->tick(1);
# if ($data && $data->{samples}) {
#     say "[DEMO] Received " . scalar($data->{samples}->@*) . " info-hash samples";
#     for my $s ($data->{samples}->@*) {
#         say "  - " . unpack("H*", $s);
#     }
# }
say "[INFO] Demo complete. See code for how to handle real responses.";
