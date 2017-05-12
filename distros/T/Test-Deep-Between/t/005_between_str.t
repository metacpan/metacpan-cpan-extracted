#!perl -w
use strict;
use Test::Tester;
use Test::More;
use Time::Piece;

use Test::Deep;
use Test::Deep::Between;

my $check_hash = {
    hoge => 'b',
};

check_test(
    sub {
        cmp_deeply $check_hash, {
            hoge => between_str('a', 'c'),
        };
    },
    {
        actual_ok => 1,
        diag => '',
    },
    'got is in a to c'
);

done_testing;
