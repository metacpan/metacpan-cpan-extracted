#!perl

use Test::More tests => 47;
use Test::Memory::Cycle;

use SNA::Network;
use List::Util qw(sum);
use List::MoreUtils qw(all);


use Devel::Cycle;
use Devel::Peek;

my $net = SNA::Network->new();
isa_ok($net, 'SNA::Network', 'test network');

my $net2 = SNA::Network->new();

# nodes

my $node_a = $net->create_node_at_index(index => 0, name => 'A');
isa_ok($node_a, 'SNA::Network::Node', 'test node A');
is($node_a->index(), 0, 'index created');
is($node_a->{name}, 'A', 'name created');

my $node_b = $net->create_node_at_index(index => 1, name => 'B');
isa_ok($node_b, 'SNA::Network::Node', 'test node B');
is($node_b->index(), 1, 'index created');
is($node_b->{name}, 'B', 'name created');

is(int $net->nodes(), 2, 'nodes created');


# node creation with automatic indexing

my $node_c = $net2->create_node(name => 'C');
isa_ok($node_c, 'SNA::Network::Node', 'test node C');
is($node_c->index, 0, 'index created');
is($node_c->{name}, 'C', 'name created');

my $node_d = $net2->create_node(name => 'D');
isa_ok($node_d, 'SNA::Network::Node', 'test node D');
is($node_d->index, 1, 'index created');
is($node_d->{name}, 'D', 'name created');

is(int $net2->nodes, 2, 'nodes created');



# edges

my $edge = $net->create_edge(source_index => 0, target_index => 1, weight => 1);
isa_ok($edge, 'SNA::Network::Edge', 'test edge');
is($edge->source(), $node_a, 'source connected');
is($edge->target(), $node_b, 'target connected');
is($edge->weight(), 1, 'weight created');

is(int $net->edges(), 1, 'edges created');

# network structure

is(int $node_a->edges(), 1, 'node A connected');
is(int $node_a->outgoing_edges(), 1, 'node A direction');
is(int $node_a->incoming_edges(), 0, 'node A direction');

is(int $node_b->edges(), 1, 'node B connected');
is(int $node_b->incoming_edges(), 1, 'node B direction');
is(int $node_b->outgoing_edges(), 0, 'node B direction');

# degrees
is($node_a->in_degree, 0, 'node A indegree');
is($node_a->out_degree, 1, 'node A outdegree');
is($node_a->summed_degree, 1, 'node A summed degree');
is($node_b->in_degree, 1, 'node B indegree');
is($node_b->out_degree, 0, 'node B outdegree');
is($node_b->summed_degree, 1, 'node B summed degree');

# loops
my $loop = $net->create_edge(source_index => 0, target_index => 0, weight => 1);
is( $node_a->loop, $loop, 'loop A found');
is( $node_b->loop, undef, 'loop B not defined' );


my $net3 = SNA::Network->new();
$net3->load_from_pajek_net('t/test-network-2.net');

# total weight
is( $net3->total_weight, 7, 'total weight of edges' );

# deleting nodes
$net3->delete_nodes($net3->node_at_index(2), $net3->node_at_index(4));
memory_cycle_ok($net3, "net contains memory cycles");

is(int $net3->nodes(), 5, '5 nodes left');
is(int $net3->edges(), 2, '2 edges left');

	
# deleting edges in any arbitrary order
my $net4 = SNA::Network->new();
$net4->load_from_pajek_net('t/test-network-2.net');
is(int $net4->node_at_index(2)->edges, 4, '4 edges at node C');
$net4->delete_edges( @{$net4->{edges}}[3,2,1] );
is(int $net4->nodes(), 7, '7 nodes left');
is(int $net4->edges(), 4, '4 edges left');
is(int $net4->node_at_index(2)->edges, 1, '1 edge left at node C');
is(sum( map { int $_->edges } $net4->nodes), 8, 'nodes contain 8 edge endpoints');

ok(( all { length $_->source->{name} == 1 } $net4->edges ), 'all edge sources have names');


# 0-weight edges
my $net5 = SNA::Network->new();
$net5->load_from_pajek_net('t/test-network-3.net');
is($net5->{edges}->[0]->weight, 0, "0 weight loaded correctly");


# community structure
ok(defined $net5->communities, "communities returns something defined without algorithm executed");
is(int($net5->communities), 0, "communities list is empty without algorithm executed");

