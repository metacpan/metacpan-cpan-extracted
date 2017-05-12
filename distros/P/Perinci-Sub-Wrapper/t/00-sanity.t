#!perl

# test a single test_wrap() for a very simple sub+meta and a fairly complete
# args for test_wrap(), just to test that basic things work.

use 5.010;
use strict;
use warnings;

use Test::More 0.98;
use Test::Perinci::Sub::Wrapper qw(test_wrap);

test_wrap(
    name               => 'sanity',
    wrap_args          => {
        sub            => sub{[200,"OK","x"]},
        meta           => {v=>1.1},
    },
    wrap_status        => 200,

    call_argsr         => [],
    call_status        => 200,
    call_res           => [200,"OK","x"],
    call_actual_res_re => qr/x/,

    calls              => [
        {
            argsr          => [],
            status         => 200,
            res            => [200,"OK","x"],
            actual_res_res => qr/x/,
        },
    ],

    posttest    => sub {
        my ($wrap_res, $call_res) = @_;
        is(ref($wrap_res), 'ARRAY', 'wrap_res is an array');
        is(ref($call_res), 'ARRAY', 'call_res is an array');
    },
);

DONE_TESTING:
done_testing;
