#!perl -w
use strict;
use Test::Tester;
use Test::More;
use Test::Output;

use Test::Deep;
use Test::Deep::Between;

my $check_hash = {
    hoge => 'one',
};

stderr_like {
    check_test(
        sub {
            cmp_deeply $check_hash, {
                hoge => between(0, 10),
            };
        },
        {
            actual_ok => 1,
            diag => '',
        },
        'got is not a number.'
    );
} qr/^Argument "one" isn't numeric in numeric le \(<=\) at .+$/, 'Output warnings invalid compare.';

done_testing;
