use strict;
use warnings;
use Test::More 0.89;
use Test::Fatal;

use NanoMsg::Raw;

my $socket_address = 'inproc://test';

{
    my $sb = nn_socket AF_SP, NN_PAIR;
    ok defined $sb;
    ok defined nn_bind $sb, $socket_address;

    my $sc = nn_socket AF_SP, NN_PAIR;
    ok defined $sc;
    ok defined nn_connect $sc, $socket_address;

    my $buf1 = nn_allocmsg 256, 0;
    ok defined $buf1;
    $buf1->copy(join '' => map chr, 0 .. 255);

    is nn_send($sc, $buf1, 0), 256;
    is nn_recv($sb, my $buf2, NN_MSG, 0), 256;
    is $buf2, join '' => map chr, 0 .. 255;

    $buf1 = nn_allocmsg 256, 0;
    ok defined $buf1;
    $buf1->copy(join '' => map chr, 0 .. 255);

    is nn_sendmsg($sc, 0, $buf1), 256;
    is nn_recvmsg($sb, 0, $buf2 => NN_MSG), 256;
    is $buf2, join '' => map chr, 0 .. 255;

    ok nn_close $_ for $sc, $sb;
}

{
    my $sb = nn_socket AF_SP, NN_PAIR;
    ok defined $sb;
    ok defined nn_bind $sb, $socket_address;

    my $sc = nn_socket AF_SP, NN_PAIR;
    ok defined $sc;
    ok defined nn_connect $sc, $socket_address;

    my $m = NanoMsg::Raw::nn_allocmsg(3, 0);
    isa_ok $m, 'NanoMsg::Raw::Message';

    like exception {
        ${ $m } = 'asd';
    }, qr/^Modification of a read-only value attempted/;

    like exception {
        $m->copy('fooo');
    }, qr/^Trying to copy 4 bytes into a message buffer of size 3/;

    $m->copy('foo');
    is $m, 'foo';

    is nn_send($sc, $m, 0), 3;
    isa_ok $m, 'NanoMsg::Raw::Message::Freed';

    {
        my $destroyed = 0;
        my $buf = ScopeGuard->new(sub { $destroyed++ });

        is nn_recv($sb, $buf, NN_MSG, 0), 3;
        is $buf, 'foo';
        is $destroyed, 1;
    }

    {
        package ScopeGuard;
        sub new { bless $_[1] }
        sub DESTROY { shift->() }
    }
}

done_testing;
