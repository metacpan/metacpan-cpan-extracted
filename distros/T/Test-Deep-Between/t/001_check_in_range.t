#!perl -w
use strict;
use Test::Tester;
use Test::More;

use Test::Deep;
use Test::Deep::Between;

# test Test::Deep::Between here

my $check_hash = {
    hoge => 1
};

check_test(
    sub {
        cmp_deeply $check_hash, {
            hoge => between(0, 1),
        };
    },
    {
        actual_ok => 1,
        diag => '',
    },
    'got is in 0 to 1'
);

check_test(
    sub {
        cmp_deeply $check_hash, {
            hoge => between(2, 6),
        };
    },
    {
        actual_ok => 0,
        diag => '$data->{"hoge"} is not in 2 to 6.',
    },
    'got is in 2 to 6'
);

done_testing;
