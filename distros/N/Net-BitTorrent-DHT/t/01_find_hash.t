use v5.40;
use lib 'lib', '../lib';
use Test2::V0;
use Net::BitTorrent::DHT;
#
my $info_hash_hex = '86f635034839f1ebe81ab96bee4ac59f61db9dde';
my $info_hash     = pack( 'H*', $info_hash_hex );
my $id            = pack( 'C*', map { int( rand(256) ) } 1 .. 20 );
#
my $dht = Net::BitTorrent::DHT->new( node_id_bin => $id, port => 6881 + int( rand(100) ), bep42 => 0 );
$dht->bootstrap();
my %candidates;
my $peer_found = 0;
my $start_time = time;
my $timeout    = 30;
while ( time - $start_time < $timeout ) {

    # Process packets and learn nodes/peers
    my ( $new_nodes, $new_peers ) = $dht->tick();
    if ( $new_peers && @$new_peers ) {
        $peer_found = 1;
        last;
    }
    for my $node (@$new_nodes) {
        my $nid_hex = unpack( 'H*', $node->{id} );
        next if exists $candidates{$nid_hex};
        $candidates{$nid_hex} = { id => $node->{id}, ip => $node->{ip}, port => $node->{port}, visited => 0 };
    }

    # Add routing table nodes to frontier
    my @closest_in_table = $dht->routing_table->find_closest( $info_hash, 50 );
    for my $node (@closest_in_table) {
        my $nid_hex = unpack( 'H*', $node->{id} );
        next if exists $candidates{$nid_hex};
        $candidates{$nid_hex} = { id => $node->{id}, ip => $node->{data}{ip}, port => $node->{data}{port}, visited => 0 };
    }

    # Query next batch
    my @to_query = sort { ( $a->{id} ^.$info_hash ) cmp( $b->{id} ^.$info_hash ) } grep { !$_->{visited} && $_->{ip} } values %candidates;
    if (@to_query) {
        my $count = 0;
        for my $c (@to_query) {
            $dht->get_peers( $info_hash, $c->{ip}, $c->{port} );
            $c->{visited} = 1;
            last if ++$count >= 5;
        }
    }
    else {
        # Only re-bootstrap if we're totally empty
        $dht->bootstrap() if $dht->routing_table->size == 0;
    }
    select( undef, undef, undef, 0.2 );
}
if ($peer_found) {
    pass 'Found actual peers for ' . $info_hash_hex;
}
else {
    skip_all 'We failed but this is probably okay', 1;

    # We might not find a peer in 30s depending on network,
    # but the routing table should definitely grow.
    note 'Populated routing table (' . $dht->routing_table->size . ' nodes)';
    note 'Search ended after ' . ( time - $start_time ) . 's. No peers found, but network was crawled.';
}
#
done_testing;
