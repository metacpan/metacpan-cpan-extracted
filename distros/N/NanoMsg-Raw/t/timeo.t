use strict;
use warnings;
use Test::More 0.89;
use Time::HiRes 'gettimeofday', 'tv_interval';

use NanoMsg::Raw;

sub timeit (&) {
    my ($cb) = @_;

    my $started = [gettimeofday];
    my @ret = $cb->();

    (tv_interval($started), @ret);
}

my $s = nn_socket AF_SP, NN_PAIR;
cmp_ok $s, '>=', 0;

my $timeo = 100;
ok nn_setsockopt($s, NN_SOL_SOCKET, NN_RCVTIMEO, $timeo);

my ($elapsed, $ret) = timeit {
    nn_recv($s, my $buf, 3, 0);
};

ok !defined $ret;
ok ( nn_errno == EAGAIN or nn_errno == ETIMEDOUT );
cmp_ok $elapsed, '>=', 0.1;
cmp_ok $elapsed, '<=', 0.12;

ok nn_setsockopt($s, NN_SOL_SOCKET, NN_SNDTIMEO, $timeo);

($elapsed, $ret) = timeit {
    nn_send($s, 'ABC', 0);
};

ok !defined $ret;
ok ( nn_errno == EAGAIN or nn_errno == ETIMEDOUT );
cmp_ok $elapsed, '>=', 0.1;
cmp_ok $elapsed, '<=', 0.12;

ok nn_close $s;

done_testing;
