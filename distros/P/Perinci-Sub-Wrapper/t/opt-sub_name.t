#!perl

use 5.010;
use strict;
use warnings;

package Foo;

sub func { "foor" }

package main;
use Test::More 0.98;

use Test::Perinci::Sub::Wrapper qw(test_wrap);

test_wrap(
    name => 'specifying sub_name only instead of sub',
    wrap_args => {
        sub_name => "Foo::func",
        meta => {v=>1.1, result_naked=>1},
        convert => {result_naked=>0},
    },
    wrap_status => 200,
    posttest => sub {
        my ($wrap_res, $call_res, $sub) = @_;
        is_deeply($sub->(), [200, "OK", "foor"], "call result");
    },
);

DONE_TESTING:
done_testing();
