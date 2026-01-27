use v5.40;
use lib 'lib', '../lib';
use Test2::V0;
use Net::BitTorrent::DHT;
use Net::BitTorrent::DHT::Security;
$|++;
#
my $sec   = Net::BitTorrent::DHT::Security->new();
my $id1   = $sec->generate_node_id('127.0.0.1');
my $id2   = $sec->generate_node_id('127.0.0.1');
my $node1 = Net::BitTorrent::DHT->new( node_id_bin => $id1, port => 16881, address => '127.0.0.1' );
my $node2 = Net::BitTorrent::DHT->new( node_id_bin => $id2, port => 16882, address => '127.0.0.1' );

# Node 1 pings Node 2
$node1->ping( '127.0.0.1', 16882 );

# Allow time for packets to travel and process
for ( 1 .. 50 ) {
    $node2->tick();
    $node1->tick();
    select( undef, undef, undef, 0.01 );
}

# Verify Node 1 learned about Node 2 from the Pong
my @closest = $node1->routing_table->find_closest( $id2, 1 );
is scalar(@closest), 1,    'Node 1 found a peer';
is $closest[0]{id},  $id2, 'Node 1 learned Node 2\'s ID';
#
done_testing;
