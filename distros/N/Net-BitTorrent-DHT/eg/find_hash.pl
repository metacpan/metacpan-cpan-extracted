use v5.40;
use lib '../lib';
use Net::BitTorrent::DHT;
use Net::BitTorrent::DHT::Security;
$|++;

# The Linux ISO hash provided
my $info_hash_hex = '86f635034839f1ebe81ab96bee4ac59f61db9dde';
my $info_hash     = pack( 'H*', $info_hash_hex );

# Generate a valid BEP 42 Node ID (though we disable validation for incoming)
my $sec = Net::BitTorrent::DHT::Security->new();
my $id  = $sec->generate_node_id('127.0.0.1');
$ENV{DEBUG} //= 1;
my $dht = Net::BitTorrent::DHT->new( node_id_bin => $id, port => 6881 + int( rand(100) ), bep42 => 0 );
say '[DEMO] Seeking peers for hash: ' . $info_hash_hex;
$dht->bootstrap();

# The 'Frontier': nodes close to target that we haven't queried yet
my %candidates;
my %seen_peers;
my $timer = time;
while (1) {

    # Process incoming packets (Non-blocking)
    my ( $new_nodes, $new_peers ) = $dht->tick(0.05);

    # Process newly discovered nodes
    for my $node (@$new_nodes) {
        my $nid_hex = unpack( 'H*', $node->{id} );
        next if exists $candidates{$nid_hex};
        $candidates{$nid_hex} = { id => $node->{id}, ip => $node->{ip}, port => $node->{port}, visited => 0 };
    }

    # Process newly discovered peers!
    for my $peer (@$new_peers) {
        my $peer_key = $peer->to_string;
        unless ( $seen_peers{$peer_key}++ ) {
            say "[DEMO] FOUND PEER: $peer_key";
        }
    }

    # Periodically pump the search
    if ( time - $timer > 2 ) {

        # Merge routing table nodes into our search frontier
        my @closest_in_table = $dht->routing_table->find_closest( $info_hash, 50 );
        for my $node (@closest_in_table) {
            my $nid_hex = unpack( 'H*', $node->{id} );
            next if exists $candidates{$nid_hex};
            $candidates{$nid_hex} = { id => $node->{id}, ip => $node->{data}{ip}, port => $node->{data}{port}, visited => 0 };
        }

        # Pick the top N closest unvisited candidates
        my @to_query = sort { ( $a->{id} ^.$info_hash ) cmp( $b->{id} ^.$info_hash ) } grep { !$_->{visited} && $_->{ip} } values %candidates;
        if (@to_query) {
            my $best_dist = unpack( 'H*', $to_query[0]{id} ^.$info_hash );
            say sprintf( '[DEMO] Frontier: %d nodes. Best dist: %s', scalar( keys %candidates ), $best_dist );
            my $count = 0;
            for my $c (@to_query) {
                if ( $ENV{DEBUG} ) {
                    say '[DEMO] Querying: ' . unpack( 'H*', $c->{id} ) . ' at ' . $c->{ip} . ':' . $c->{port};
                }
                $dht->get_peers( $info_hash, $c->{ip}, $c->{port} );
                $c->{visited} = 1;
                last if ++$count >= 8;
            }
        }
        else {
            say '[DEMO] Frontier exhausted. Re-bootstrapping...';
            $dht->bootstrap();
        }
        $timer = time;
    }
}
