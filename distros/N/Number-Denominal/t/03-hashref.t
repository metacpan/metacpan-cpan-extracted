#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More ;
use Test::Deep;
# plan 'no_plan';
plan tests => 11;

use Number::Denominal;

my $data = denominal_hashref(
    12661,
        [ qw/second seconds/ ] =>
        60 => [ qw/minute minutes/ ] =>
        60 => [ qw/hour hours/ ],
);

cmp_deeply(
    $data,
    { hour => 3, minute => 31, second => 1 },
    'testing 12661 seconds',
);

cmp_deeply(
    denominal_hashref( 12661, second => 60 => minute => 60 => 'hour', ),
    $data,
    'testing unit shortcut',
);

cmp_deeply(
    denominal_hashref( 12661, \'time' ),
    $data,
    'testing unit set shortcut',
);

cmp_deeply(
    denominal_hashref(
        12661,
            [ qw/foo bars/ ] =>
            60 => [ qw/ber  beers/ ] =>
                60 => [ qw/mar meow/ ],
    ),
    { mar => 3, ber => 31, foo => 1 },
    'testing "s"-less units',
);

cmp_deeply(
    denominal_hashref( 12660, second => 60 => minute => 60 => 'hour', ),
    { hour => 3, minute => 31 },
    'testing "missing" units, when their number is 0 [test 1]',
);

cmp_deeply(
    denominal_hashref( 3*3600, second => 60 => minute => 60 => 'hour', ),
    { hour => 3 },
    'testing "missing" units, when their number is 0 [test 2]',
);

cmp_deeply(
    denominal_hashref( 0, second => 60 => minute => 60 => 'hour', ),
    +{},
    'testing "missing" units, when their number is 0 [test 3]',
);

cmp_deeply(
    denominal_hashref( 3, second => 60 => minute => 60 => 'hour', ),
    { second => 3 },
    'testing "missing" units, when their number is 0 [test 4]',
);

cmp_deeply(
    denominal_hashref( 60, second => 60 => minute => 60 => 'hour', ),
    { minute => 1 },
    'testing "missing" units, when their number is 0 [test 5]',
);

cmp_deeply(
    denominal_hashref( 62, second => 60 => minute => 60 => 'hour', ),
    { minute => 1, second => 2 },
    'testing "missing" units, when their number is 0 [test 6]',
);

cmp_deeply(
    denominal_hashref( 3601, second => 60 => minute => 60 => 'hour', ),
    { hour => 1, second => 1 },
    'testing "missing" units, when their number is 0 [test 7]',
);