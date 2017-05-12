#!perl

use Test::More tests => 9;

use SNA::Network;

my $net = SNA::Network->new();
$net->load_from_pajek_net('t/test-network-1.net');

is(int $net->nodes(), 4, 'nodes read');
is(int $net->edges(), 6, 'edges read');
is($net->node_at_index(3)->{name}, 'D', 'node D read');

my $net2 = SNA::Network->new_from_pajek_net('t/test-network-1.net');

is(int $net2->nodes(), 4, 'nodes read');
is(int $net2->edges(), 6, 'edges read');
is($net2->node_at_index(3)->{name}, 'D', 'node D read');

$net->save_to_pajek_net('t/test-network-1b.net');

my $net_b = SNA::Network->new();
$net_b->load_from_pajek_net('t/test-network-1b.net');

is(int $net_b->nodes(), 4, 'nodes saved');
is(int $net_b->edges(), 6, 'edges saved');
is($net->node_at_index(3)->{name}, 'D', 'node D saved');

unlink('t/test-network-1b.net');

