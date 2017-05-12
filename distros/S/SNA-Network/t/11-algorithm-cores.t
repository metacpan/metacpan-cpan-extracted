#!perl

use Test::More tests => 11;

use SNA::Network;

my $net = SNA::Network->new();
$net->load_from_pajek_net('t/test-network-5.net');

my $k_in_max = $net->calculate_in_ccs;

is($k_in_max, 3, 'test-network-5 k_max is 3');
is($net->node_at_index(0)->{k_in_core}, 3, 'k-in(A) is 3');
is($net->node_at_index(1)->{k_in_core}, 3, 'k-in(B) is 3');
is($net->node_at_index(2)->{k_in_core}, 3, 'k-in(C) is 3');
is($net->node_at_index(3)->{k_in_core}, 3, 'k-in(D) is 3');
is($net->node_at_index(4)->{k_in_core}, 3, 'k-in(E) is 3');
is($net->node_at_index(5)->{k_in_core}, 1, 'k-in(F) is 1');
is($net->node_at_index(6)->{k_in_core}, 1, 'k-in(G) is 1');
is($net->node_at_index(7)->{k_in_core}, 1, 'k-in(H) is 1');
is($net->node_at_index(8)->{k_in_core}, 0, 'k-in(I) is 0');
is($net->node_at_index(9)->{k_in_core}, 0, 'k-in(J) is 0');

