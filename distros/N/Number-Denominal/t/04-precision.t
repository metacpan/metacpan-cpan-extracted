#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More ;
plan 'no_plan';
# plan tests => 11;

use Number::Denominal;

my $data = denominal(
    3*3600 + 31*60 + 1,
        [ qw/second seconds/ ] =>
        60 => [ qw/minute minutes/ ] =>
        60 => [ qw/hour hours/ ],
    { precision => 2 }
);

is(
    $data,
    '3 hours and 31 minutes',
    'testing 12661 seconds',
);

is(
    denominal( 3*3600 + 31*60 + 1, second => 60 => minute => 60 => 'hour',
        { precision => 2 }
    ),
    $data,
    'testing unit shortcut',
);

is(
    denominal( 3*3600 + 31*60 + 1, \'time', { precision => 2 } ),
    $data,
    'testing ("time") units shortcut',
);

is(
    denominal( 3*3600 + 31*60 + 1, \'time', { precision => 200000 } ),
    '3 hours, 31 minutes, and 1 second',
    'testing large precision value / units shortcut',
);

eval { denominal( 3*3600 + 31*60 + 1, \'time', { precision => 0 } ) };
like(
    $@,
    qr{\Qprecision argument takes positive integers only, \E
         \Qbut its value is 0 at t\E[\\/]\Q04-precision.t line \E\d+}x,
    'testing invalid precision value',
);

is(
    denominal( 3*3600 + 31*60 + 1, \'time', { precision => 1} ),
    '4 hours', # should be rounded
    'testing rounding with precision == 1',
);

is(
    denominal( 3*3600 + 31*60 + 40, \'time', { precision => 2 } ),
    '3 hours and 32 minutes', # should be rounded
    'testing rounding with precision == 2',
);

is(
    denominal( 3*3600 + 31*60 + 40, \'time', { precision => 3 } ),
    '3 hours, 31 minutes, and 40 seconds',
    'testing rounding with precision == 3',
);

is(
    denominal( 3*3600 + 28*60 + 20, \'time', { precision => 1} ),
    '3 hours', # should NOT be rounded
    'testing non-rounding with precision == 1',
);

is(
    denominal( 3*3600 + 31*60 + 20, \'time', { precision => 2 } ),
    '3 hours and 31 minutes', # should NOT be rounded
    'testing non-rounding with precision == 2',
);

is(
    denominal( 3*3600 + 29*60 + 20, \'time', { precision => 3 } ),
    '3 hours, 29 minutes, and 20 seconds',
    'testing non-rounding with precision == 3',
);

is(
    denominal( 23*3600 + 59*60 + 59, \'time', { precision => 2 } ),
    '1 day',
    'testing multi-unit rounding with precision == 2',
);

is(
    denominal( 0, \'time', { precision => 2 } ),
    '',
    'testing zero value with precision == 2',
);

is(
    denominal( 1, \'time', { precision => 2 } ),
    '1 second',
    'testing 1-unit value with precision == 2',
);

is_deeply(
    denominal_hashref( 23*3600 + 59*60 + 59, \'time', { precision => 2 } ),
    { day => 1 },
    'testing multi-unit rounding with precision == 2; denominal_hashref',
);

is_deeply(
    [ denominal_list( 23*3600 + 59*60 + 59, \'time', { precision => 2 } ) ],
    [ 0, 1, 0, 0, 0, ],
    'testing multi-unit rounding with precision == 2; denominal_list',
);