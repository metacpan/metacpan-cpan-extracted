use v5.40;
use lib 'lib', '../lib';
use Net::BitTorrent::DHT;
use Net::BitTorrent::DHT::Security;
use Digest::SHA qw[sha1];
$|++;

# Example: Iterative search for an infohash
# This script demonstrates how to perform a proper Kademlia lookup
# for peers associated with a specific info-hash.
my $target_hex = shift // '86f635034839f1ebe81ab96bee4ac59f61db9dde';    # Linux ISO default
my $target_bin = pack( 'H*', $target_hex );
say '[INFO] Searching for peers of: ' . $target_hex;

# Initialize DHT node
my $sec = Net::BitTorrent::DHT::Security->new();
my $id  = $sec->generate_node_id('127.0.0.1');                           # Local testing ID
my $dht = Net::BitTorrent::DHT->new(
    node_id_bin => $id,
    port        => 6881 + int( rand(100) ),
    bep42       => 0                                                     # Disable validation for demo if you don't have real external IP
);

# Start bootstrapping
say '[INFO] Bootstrapping...';
$dht->bootstrap();

# Search state
my %frontier;                          # nodes we've found but haven't queried yet
my %visited;                           # nodes we've already queried
my %peers;                             # peers we've found
my $start_time = time;
my $last_query = 0;
while ( time - $start_time < 60 ) {    # Run for 60 seconds max
    my ( $nodes, $new_peers ) = $dht->tick(0.1);

    # Add newly discovered nodes to our frontier
    for my $n (@$nodes) {
        my $nid = $n->{id};
        my $hex = unpack( 'H*', $nid );
        next if $visited{$hex} || $frontier{$hex};
        $frontier{$hex} = $n;
    }

    # Record any new peers found
    for my $p (@$new_peers) {
        my $addr = $p->to_string;
        say '[FOUND] Peer: ' . $addr unless $peers{$addr}++;
    }

    # Every 2 seconds, pick the closest unvisited nodes and query them
    if ( time - $last_query > 2 ) {

        # Also include nodes from our own routing table in the frontier
        my @closest_local = $dht->routing_table->find_closest( $target_bin, 20 );
        for my $n (@closest_local) {
            my $hex = unpack( 'H*', $n->{id} );
            next if $visited{$hex} || $frontier{$hex};
            $frontier{$hex} = { id => $n->{id}, ip => $n->{data}{ip}, port => $n->{data}{port} };
        }

        # Sort frontier by distance to target
        my @sorted = sort { ( $a->{id} ^.$target_bin ) cmp ( $b->{id} ^.$target_bin ) } values %frontier;

        # Query top 8 closest unvisited nodes
        my $count = 0;
        for my $n (@sorted) {
            my $hex = unpack( 'H*', $n->{id} );
            say "[SEARCH] Querying node $hex at $n->{ip}:$n->{port}";
            $dht->get_peers( $target_bin, $n->{ip}, $n->{port} );
            $visited{$hex} = delete $frontier{$hex};
            last if ++$count >= 8;
        }
        if ( $count == 0 && !%frontier ) {
            say '[INFO] Frontier empty. Re-bootstrapping...';
            $dht->bootstrap();
        }
        $last_query = time;
        say sprintf '[STATS] Frontier: %d, Visited: %d, Peers: %d', scalar( keys %frontier ), scalar( keys %visited ), scalar( keys %peers );
    }
}
say '[INFO] Search complete.';
