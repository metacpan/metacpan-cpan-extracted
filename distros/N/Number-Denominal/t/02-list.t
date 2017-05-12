#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More ;
use Test::Deep;
# plan 'no_plan';
plan tests => 12;

use Number::Denominal;

my $data = [denominal_list(
    12661,
        [ qw/second seconds/ ] =>
        60 => [ qw/minute minutes/ ] =>
        60 => [ qw/hour hours/ ],
)];
cmp_deeply(
    $data,
    [ 3, 31, 1 ],
    'testing 12661 seconds',
);

cmp_deeply(
    [denominal_list( 12661, second => 60 => minute => 60 => 'hour', )],
    $data,
    'testing unit shortcut',
);

cmp_deeply(
    [denominal_list( 12661, \'time')],
    [ 0, 0, 3, 31, 1 ],
    'testing unit set shortcut',
);

cmp_deeply(
    [denominal_list( 12661, [qw/60  60/])],
    [ 3, 31, 1 ],
    'testing unitless shortcut',
);

cmp_deeply(
    [denominal_list(
        12661,
            [ qw/foo bars/ ] =>
                60 => [ qw/ber  beers/ ] =>
                    60 => [ qw/mar meow/ ],
    )],
    [ 3, 31, 1 ],
    'testing "s"-less units',
);


cmp_deeply(
    [denominal_list( 12660, second => 60 => minute => 60 => 'hour', )],
    [ 3, 31, 0],
    'testing "missing" units, when their number is 0 [test 1]',
);

cmp_deeply(
    [denominal_list( 3*3600, second => 60 => minute => 60 => 'hour', )],
    [3, 0, 0],
    'testing "missing" units, when their number is 0 [test 2]',
);

cmp_deeply(
    [denominal_list( 0, second => 60 => minute => 60 => 'hour', )],
    [0, 0, 0],
    'testing "missing" units, when their number is 0 [test 3]',
);

cmp_deeply(
    [denominal_list( 3, second => 60 => minute => 60 => 'hour', )],
    [ 0, 0, 3 ],
    'testing "missing" units, when their number is 0 [test 4]',
);

cmp_deeply(
    [denominal_list( 60, second => 60 => minute => 60 => 'hour', )],
    [ 0, 1, 0 ],
    'testing "missing" units, when their number is 0 [test 5]',
);

cmp_deeply(
    [denominal_list( 62, second => 60 => minute => 60 => 'hour', )],
    [ 0, 1, 2 ],
    'testing "missing" units, when their number is 0 [test 6]',
);

cmp_deeply(
    [denominal_list( 3601, second => 60 => minute => 60 => 'hour', )],
    [1, 0, 1],
    'testing "missing" units, when their number is 0 [test 7]',
);