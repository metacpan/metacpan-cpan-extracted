#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More ;
# plan 'no_plan';
plan tests => 11;

use Number::Denominal;

my $data = denominal(
    12661,
        [ qw/second seconds/ ] =>
        60 => [ qw/minute minutes/ ] =>
        60 => [ qw/hour hours/ ],
);

is(
    $data,
    '3 hours, 31 minutes, and 1 second',
    'testing 12661 seconds',
);

is(
    denominal( 12661, second => 60 => minute => 60 => 'hour', ),
    $data,
    'testing unit shortcut',
);

is(
    denominal( 12661, \'time' ),
    $data,
    'testing "time" units shortcut',
);

is(
    denominal(
        12661,
            [ qw/foo bars/ ] =>
            60 => [ qw/ber  beers/ ] =>
                60 => [ qw/mar meow/ ],
    ),
    '3 meow, 31 beers, and 1 foo',
    'testing "s"-less units',
);


is(
    denominal( 12660, second => 60 => minute => 60 => 'hour', ),
    '3 hours and 31 minutes',
    'testing "missing" units, when their number is 0 [test 1]',
);

is(
    denominal( 3*3600, second => 60 => minute => 60 => 'hour', ),
    '3 hours',
    'testing "missing" units, when their number is 0 [test 2]',
);

is(
    denominal( 0, second => 60 => minute => 60 => 'hour', ),
    '',
    'testing "missing" units, when their number is 0 [test 3]',
);

is(
    denominal( 3, second => 60 => minute => 60 => 'hour', ),
    '3 seconds',
    'testing "missing" units, when their number is 0 [test 4]',
);

is(
    denominal( 60, second => 60 => minute => 60 => 'hour', ),
    '1 minute',
    'testing "missing" units, when their number is 0 [test 5]',
);

is(
    denominal( 62, second => 60 => minute => 60 => 'hour', ),
    '1 minute and 2 seconds',
    'testing "missing" units, when their number is 0 [test 6]',
);

is(
    denominal( 3601, second => 60 => minute => 60 => 'hour', ),
    '1 hour and 1 second',
    'testing "missing" units, when their number is 0 [test 7]',
);