use v5.40;
use lib 'lib', '../lib';
use Test2::V0;
use Net::BitTorrent::DHT;
use Net::BitTorrent::DHT::Security;
#
my $node_count = 20;    # 20 nodes is plenty for a visible crawl
my @nodes;
my $sec              = Net::BitTorrent::DHT::Security->new();
my $info_hash        = pack 'H*', 'ff' . ( '00' x 19 );    # Very 'high' hash
my $target_peer_ip   = '10.0.0.20';
my $target_peer_port = 5555;
diag sprintf 'Creating %d nodes...', $node_count;

for my $i ( 0 .. $node_count - 1 ) {
    my $id  = $sec->generate_node_id('127.0.0.1');
    my $dht = Net::BitTorrent::DHT->new( node_id_bin => $id, port => 17000 + $i, address => '127.0.0.1' );
    push @nodes, $dht;
}
diag 'Seeding target peer on Node ' . ( $node_count - 1 );
$nodes[-1]->peer_storage->put( $info_hash, [ { ip => $target_peer_ip, port => $target_peer_port } ] );
diag 'Building knowledge chain...';
for my $i ( 0 .. $node_count - 2 ) {
    $nodes[$i]->routing_table->add_peer( $nodes[ $i + 1 ]->node_id_bin, { ip => '127.0.0.1', port => $nodes[ $i + 1 ]->port } );
    $nodes[ $i + 1 ]->routing_table->add_peer( $nodes[$i]->node_id_bin, { ip => '127.0.0.1', port => $nodes[$i]->port } );
}
my %candidates;
my $found = 0;
diag 'Node 0 starting search for info_hash: ' . unpack( 'H*', $info_hash );
$nodes[0]->get_peers( $info_hash, '127.0.0.1', $nodes[1]->port );
my $start = time;
while ( time - $start < 30 && !$found ) {
    for my $i ( 0 .. $#nodes ) {
        my $n = $nodes[$i];
        my ( $new_nodes, $new_peers ) = $n->tick(0);
        if ( $i == 0 ) {
            for my $node (@$new_nodes) {
                my $hex = unpack( 'H*', $node->{id} );
                unless ( exists $candidates{$hex} ) {
                    my $dist = unpack( 'H*', $node->{id} ^.$info_hash );
                    diag sprintf 'Node 0 discovered node: %s (dist: %s)', $hex, $dist;
                    $candidates{$hex} = { %$node, visited => 0 };
                }
            }
            if (@$new_peers) {
                diag 'Node 0 FOUND TARGET PEER at ' . $new_peers->[0]->to_string;
                is $new_peers->[0]->ip, $target_peer_ip, 'Node 0 found the correct peer IP';
                $found = 1;
                last;
            }
            my @unvisited = sort { ( $a->{id} ^.$info_hash ) cmp( $b->{id} ^.$info_hash ) } grep { !$_->{visited} } values %candidates;
            if (@unvisited) {
                my $next     = $unvisited[0];
                my $next_hex = unpack( 'H*', $next->{id} );
                diag 'Node 0 querying closer: ' . $next_hex;
                $nodes[0]->get_peers( $info_hash, $next->{ip}, $next->{port} );
                $next->{visited} = 1;
            }
        }
    }
    select( undef, undef, undef, 0.05 );
}
ok $found, 'Successfully crawled the chain to find the peer';
#
done_testing;
