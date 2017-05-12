use strict;
use warnings;
use Test::More 0.89;

use NanoMsg::Raw;

my $socket_address_a = 'inproc://a';
my $socket_address_b = 'inproc://b';

my $pull1 = nn_socket(AF_SP, NN_PULL);
ok defined $pull1;
ok defined nn_bind($pull1, $socket_address_a);

my $pull2 = nn_socket(AF_SP, NN_PULL);
ok defined $pull2;
ok defined nn_bind($pull2, $socket_address_b);

my $push = nn_socket(AF_SP, NN_PUSH);
ok defined $push;

ok nn_setsockopt($push, NN_SOL_SOCKET, NN_SNDPRIO, 1);
ok defined nn_connect($push, $socket_address_a);

ok nn_setsockopt($push, NN_SOL_SOCKET, NN_SNDPRIO, 2);
ok defined nn_connect($push, $socket_address_b);

is nn_send($push, 'ABC', 0), 3;
is nn_send($push, 'DEF', 0), 3;

is nn_recv($pull1, my $buf, 3, 0), 3;
is nn_recv($pull1, $buf, 3, 0), 3;

ok nn_close $_ for $pull1, $push, $pull2;

done_testing;
