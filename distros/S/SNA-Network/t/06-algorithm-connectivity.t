#!perl

use Test::More tests => 8;

use SNA::Network;

my $net = SNA::Network->new();
$net->load_from_pajek_net('t/test-network-2.net');

my $num_weak_components = $net->identify_weak_components();

is($num_weak_components, 3, 'test-network-2 has 3 weak components');
is($net->node_at_index(0)->{weak_component_id}, 0, 'weak_component_id of node 0');
is($net->node_at_index(1)->{weak_component_id}, 0, 'weak_component_id of node 1');
is($net->node_at_index(2)->{weak_component_id}, 0, 'weak_component_id of node 2');
is($net->node_at_index(3)->{weak_component_id}, 0, 'weak_component_id of node 3');
is($net->node_at_index(4)->{weak_component_id}, 1, 'weak_component_id of node 4');
is($net->node_at_index(5)->{weak_component_id}, 1, 'weak_component_id of node 5');
is($net->node_at_index(6)->{weak_component_id}, 2, 'weak_component_id of node 6');

