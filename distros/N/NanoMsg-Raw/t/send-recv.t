use strict;
use warnings;
use Test::More 0.89;

use NanoMsg::Raw;

# Tests all posssible variations of nn_send and nn_recv
# It is also stress test for our receive buffer.
#
# nn_send( $s, $buf )
# nn_send( $s, $buf, $flags )
#
# nn_recv( $s, $buf )
# nn_recv( $s, $buf, NN_MSG )
# nn_recv( $s, $buf, 123 )
# nn_recv( $s, $buf, 123, 0 )
# nn_recv( $s, $buf, NN_MSG, 0 )
# nn_recv( $s, $buf, 123, NN_DONTWAIT )
# nn_recv( $s, $buf, NN_MSG, NN_DONTWAIT )

# reusing the buf variable might trigger
#
# perl(91339,0x7fff75f71180) malloc: *** error for object 0x7fa722024a70: pointer being realloc'd was not allocated
# *** set a breakpoint in malloc_error_break to debug
#
# and
# sv_upgrade from type 5 down to type 2 at t/send-recv.t line 66.

my $socket_address = 'inproc://test';

my $pub = nn_socket AF_SP, NN_PUB;
ok defined nn_bind $pub, $socket_address;

my @subs;
for ( 1 .. 7 ) {
    push @subs, my $sub = nn_socket AF_SP, NN_SUB;
    ok defined $sub;
    ok defined nn_setsockopt( $sub, NN_SUB, NN_SUB_SUBSCRIBE, '' );
    ok defined nn_connect $sub, $socket_address;
}

my $msg  = 'Hi there';
my $mlen = length($msg);
is nn_send( $pub, $msg ), $mlen;
is nn_send( $pub, $msg, 0 ), $mlen;

my $buf;

# buffer is large enough for the string
is nn_recv( $subs[0], $buf ), $mlen;
is length($buf), $mlen;
is nn_recv( $subs[1], $buf, NN_MSG ), $mlen;
is length($buf), $mlen;
is nn_recv( $subs[2], $buf, $mlen ), $mlen;
is length($buf), $mlen;
is nn_recv( $subs[3], $buf, NN_MSG, 0 ), $mlen;
is length($buf), $mlen;
is nn_recv( $subs[4], $buf, $mlen, 0 ), $mlen;
is length($buf), $mlen;
is nn_recv( $subs[5], $buf, NN_MSG, NN_DONTWAIT ), $mlen;
is length($buf), $mlen;
is nn_recv( $subs[6], $buf, $mlen, NN_DONTWAIT ), $mlen;
is length($buf), $mlen;

# receive the whole message
is nn_recv( $subs[0], $buf ), $mlen;
is length($buf), $mlen;

# receive only a few bytes - mixed with requests for the whole message
# while reusing the buffer.
my $bsize = int( $mlen / 2 );
is nn_recv( $subs[1], $buf, NN_MSG ), $mlen;
is length($buf), $mlen;
is nn_recv( $subs[2], $buf, $bsize ), $mlen;
is length($buf), $bsize;
is nn_recv( $subs[3], $buf, NN_MSG, 0 ), $mlen;
is length($buf), $mlen;
is nn_recv( $subs[4], $buf, $bsize, 0 ), $mlen;
is length($buf), $bsize;
is nn_recv( $subs[5], $buf, NN_MSG, NN_DONTWAIT ), $mlen;
is length($buf), $mlen;
is nn_recv( $subs[6], $buf, $bsize, NN_DONTWAIT ), $mlen;
is length($buf), $bsize;

# there is nothing left to receive
my $str = $buf = 'This buffer should not change';
ok !defined nn_recv( $subs[3], $buf, $bsize, NN_DONTWAIT );
is $buf, $str;

ok nn_close $_ for $pub, @subs;

done_testing;
