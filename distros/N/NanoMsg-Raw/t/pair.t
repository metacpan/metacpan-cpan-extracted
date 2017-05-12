use strict;
use warnings;
use Test::More 0.89;

use NanoMsg::Raw;

my $socket_address = 'inproc://a';

my $sb = nn_socket(AF_SP, NN_PAIR);
ok defined $sb;
ok defined nn_bind($sb, $socket_address);

my $sc = nn_socket(AF_SP, NN_PAIR);
ok defined $sc;
ok defined nn_connect($sc, $socket_address);

is nn_send($sc, 'ABC', 0), 3;
is nn_recv($sb, my $buf, 3, 0), 3;

is nn_send($sb, 'DEF', 0), 3;
is nn_recv($sc, $buf, 3, 0), 3;

ok nn_close $_ for $sc, $sb;

done_testing;
