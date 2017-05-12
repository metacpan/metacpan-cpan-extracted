use strict;
use warnings;
use Test::More 0.89;

use NanoMsg::Raw;

my $socket_address_a = 'inproc://a';
my $socket_address_b = 'inproc://b';

# Create a simple bus topology consisting of 3 nodes.
my $bus1 = nn_socket(AF_SP, NN_BUS);
cmp_ok $bus1, '>=', 0;
cmp_ok nn_bind($bus1, $socket_address_a), '>=', 0;

my $bus2 = nn_socket(AF_SP, NN_BUS);
cmp_ok $bus2, '>=', 0;
cmp_ok nn_bind($bus2, $socket_address_b), '>=', 0;
cmp_ok nn_connect($bus2, $socket_address_a), '>=', 0;

my $bus3 = nn_socket(AF_SP, NN_BUS);
cmp_ok $bus3, '>=', 0;
cmp_ok nn_connect($bus3, $socket_address_a), '>=', 0;
cmp_ok nn_connect($bus3, $socket_address_b), '>=', 0;

# Send a message from each node.
is nn_send($bus1, 'A', 0), 1;
is nn_send($bus2, 'AB', 0), 2;
is nn_send($bus3, 'ABC', 0), 3;

# Check that two messages arrived at each node.
my $ret = nn_recv($bus1, my $buf, 3, 0);
ok $ret == 2 || $ret == 3;
$ret = nn_recv($bus1, $buf, 3, 0);
ok $ret == 2 || $ret == 3;

$ret = nn_recv($bus2, $buf, 3, 0);
ok $ret == 1 || $ret == 3;
$ret = nn_recv($bus2, $buf, 3, 0);
ok $ret == 1 || $ret == 3;

$ret = nn_recv($bus3, $buf, 3, 0);
ok $ret == 1 || $ret == 2;
$ret = nn_recv($bus3, $buf, 3, 0);
ok $ret == 1 || $ret == 2;

ok nn_close($_) for $bus3, $bus2, $bus1;

done_testing;
