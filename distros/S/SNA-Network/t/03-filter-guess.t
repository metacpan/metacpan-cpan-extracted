#!perl

use Test::More tests => 16;

use SNA::Network;

my $net = SNA::Network->new();
$net->load_from_gdf('t/test-network-1.gdf');

is(int $net->nodes(), 4, 'nodes read');
is(int $net->edges(), 6, 'edges read');
is($net->node_at_index(3)->{name}, 'D', 'node D read');
is($net->node_at_index(1)->{field1}, 'c', 'field1 read');
is($net->node_at_index(2)->{field2}, 'f', 'field2 read');


my ($edge1) = $net->edges();
is($edge1->{weight}, 1, 'weight loaded');

my $net2 = SNA::Network->new_from_gdf('t/test-network-1.gdf');

is(int $net2->nodes(), 4, 'nodes read');
is(int $net2->edges(), 6, 'edges read');
is($net2->node_at_index(3)->{name}, 'D', 'node D read');
is($net2->node_at_index(1)->{field1}, 'c', 'field1 read');
is($net2->node_at_index(2)->{field2}, 'f', 'field2 read');


my ($edge2) = $net2->edges();
is($edge2->{weight}, 1, 'weight loaded');

$net->save_to_gdf(filename => 't/test-network-1b.gdf', node_fields => ['field1','field2'], edge_fields => ['weight']);

my $net_b = SNA::Network->new();
$net_b->load_from_gdf('t/test-network-1b.gdf');

is(int $net_b->nodes(), 4, 'nodes saved');
is(int $net_b->edges(), 6, 'edges saved');
is($net_b->node_at_index(3)->{name}, 'D', 'node D saved');

my ($edge1_b) = $net_b->edges();
is($edge1_b->{weight}, 1, 'weight saved');

unlink('t/test-network-1b.gdf');

