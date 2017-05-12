#!perl

use Test::More tests => 16;

use SNA::Network;

my $net = SNA::Network->new();
$net->load_from_pajek_net('t/test-network-4.net');

$net->calculate_betweenness();

# check betweenness values

is($net->node_at_index(0)->{betweenness}, 0,     'A has betweenness 0.0');
is($net->node_at_index(1)->{betweenness}, 0.5/6, 'B has betweenness 0.083');
is($net->node_at_index(2)->{betweenness}, 0.5/6, 'C has betweenness 0.083');
is($net->node_at_index(3)->{betweenness}, 0,     'D has betweenness 0.0');

is($net->{edges}->[0]->{betweenness}, 1.5/12,     'A->B has betweenness 0.125');
is($net->{edges}->[1]->{betweenness}, 1.5/12,     'A->C has betweenness 0.125');
is($net->{edges}->[2]->{betweenness}, 1.5/12,     'B->D has betweenness 0.125');
is($net->{edges}->[3]->{betweenness}, 1.5/12,     'C->D has betweenness 0.125');


$net->calculate_betweenness( normalise => 0);

# check unnormalised betweenness values

is($net->node_at_index(0)->{betweenness}, 0,     'A has betweenness 0.0');
is($net->node_at_index(1)->{betweenness}, 0.5, 'B has betweenness 0.5');
is($net->node_at_index(2)->{betweenness}, 0.5, 'C has betweenness 0.5');
is($net->node_at_index(3)->{betweenness}, 0,     'D has betweenness 0.0');

is($net->{edges}->[0]->{betweenness}, 1.5,     'A->B has betweenness 1.5');
is($net->{edges}->[1]->{betweenness}, 1.5,     'A->C has betweenness 1.5');
is($net->{edges}->[2]->{betweenness}, 1.5,     'B->D has betweenness 1.5');
is($net->{edges}->[3]->{betweenness}, 1.5,     'C->D has betweenness 1.5');


