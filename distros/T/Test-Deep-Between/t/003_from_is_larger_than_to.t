#!perl -w
use strict;
use Test::Tester;
use Test::More;

use Test::Deep;
use Test::Deep::Between;

my $check_hash = {
    hoge => 2,
};

check_test(
    sub {
        cmp_deeply $check_hash, {
            hoge => between(2, 1),
        };
    },
    {
        actual_ok => 0,
        diag => 'from_value is larger than to_value.',
    },
    'from is larger than to.'
);

done_testing;
