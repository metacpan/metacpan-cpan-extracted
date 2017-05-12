use strict;
use warnings;
use Test::More 0.89;

use NanoMsg::Raw;

my $socket_address = 'inproc://a';

my $sb = nn_socket AF_SP, NN_PAIR;
cmp_ok $sb, '>=', 0;
cmp_ok nn_bind($sb, $socket_address), '>=', 0;

my $sc = nn_socket AF_SP, NN_PAIR;
cmp_ok $sc, '>=', 0;
cmp_ok nn_connect($sc, $socket_address), '>=', 0;

my $buf1 = 'ABCDEFGHIJKLMNO';
my $buf2 = 'PQRSTUVWXYZ';

is nn_sendmsg($sc, 0, $buf1, $buf2), 26;

is nn_recvmsg($sb, 0, my $buf3 => 15, my $buf4 => 15), 26;
is $buf3, $buf1;
is $buf4, $buf2;

is nn_sendmsg($sc, 0, $buf1, $buf2), 26;

is nn_recvmsg($sb, 0, my $buf5 => 26, my $buf6 => 26, my $buf7 => 26), 26;
is $buf5, $buf1 . $buf2;
is $buf6, '';
is $buf7, '';

done_testing;
