#!perl -w
use strict;

use Test::Tester;
use Test::More;

use Test::Deep;
use Test::Deep::Cond;

check_test sub {
    cmp_deeply(
        {
            hoge => 3,
        },
        {
            hoge => cond { 2 < $_ and $_ < 4 },
        },
    );
}, {
    ok => 1,
};

check_test sub {
    cmp_deeply(
        {
            hoge => 3,
        },
        {
            hoge => cond { 1 < $_ and $_ < 3 },
        },
    );
}, {
    ok => 0,
    diag => q!$data->{"hoge"} return '3'!,
};

done_testing;
