#!perl

use Test::More tests => 2;

use SNA::Network;

my $net = SNA::Network->new();
is($net->network_plugin_test(), 1, 'network test plugin loaded');

my $node = $net->create_node_at_index(index => 0, name => 'A');
is($node->node_plugin_test(), 1, 'node test plugin loaded');

