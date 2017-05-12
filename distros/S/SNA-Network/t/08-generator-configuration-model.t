#!perl

use Test::More tests => 3;

use SNA::Network;

my $base_net = SNA::Network->new;
$base_net->load_from_pajek_net('t/test-network-2.net');

my $rand_net = SNA::Network->new;
$rand_net->generate_by_configuration_model( $base_net );

is(int $rand_net->nodes, 7, 'nodes of random network generated');
ok(int $rand_net->edges >= 5, 'at least 5 edges in random network');
ok(int $rand_net->edges <= 7, 'at most 7 edges in random network');

