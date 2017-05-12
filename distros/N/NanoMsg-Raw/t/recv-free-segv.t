use strict;
use warnings;
use Test::More tests => 6;
use NanoMsg::Raw;
my $url = 'ipc:///tmp/survey.ipc';
ok defined( my $sock = nn_socket( AF_SP, NN_SURVEYOR ) );
ok nn_setsockopt( $sock, NN_SURVEYOR, NN_SURVEYOR_DEADLINE, 1000 );
ok defined nn_bind( $sock, $url );
is nn_send( $sock, 'MESSAGE' ), 7;
# $res is upgraded to NanoMsg::Raw::Message but we do not receive data
# in this test and NanoMsg::Raw::Message segfault on destruction.
{ ok !defined( nn_recv( $sock, my $res ) ); }
# give it some time
sleep 2;
# do one last test otherwise all tests pass but we segfault at the end.
ok 1;

