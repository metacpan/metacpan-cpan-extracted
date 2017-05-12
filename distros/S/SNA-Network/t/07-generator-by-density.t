#!perl

use Test::More tests => 6;

use SNA::Network;

my $net1 = SNA::Network->new();
$net1->generate_by_density( nodes => 100, density => 0.05);

is(int $net1->nodes, 100, 'nodes of network 1 generated correctly');
ok(int $net1->edges > 300, 'edges of network 1 generated as expected');
ok(int $net1->edges < 600, 'edges of network 1 generated as expected');


my $net2 = SNA::Network->new();
$net2->generate_by_density( nodes => 100, edges => 445);

is(int $net2->nodes, 100, 'nodes of network 2 generated correctly');
ok(int $net2->edges > 300, 'edges of network 2 generated as expected');
ok(int $net2->edges < 600, 'edges of network 2 generated as expected');

