#!perl -T

use strict;
use warnings FATAL => 'all';

use Test::More;

use lib "t";
use _common;

my @TESTS = (
    {
        a       => 0,
        b       => undef,
        name    => '0_vs_undef',
        diff    => {N => undef,O => 0},
    },
    {
        a       => 0,
        b       => 0,
        name    => '0_vs_0',
        diff    => {U => 0},
    },
    {
        a       => 0,
        b       => 0,
        name    => '0_vs_0_noU',
        diff    => {},
        opts    => {noU => 1},
    },
    {
        a       => 0,
        b       => 1,
        name    => '0_vs_1',
        diff    => {N => 1,O => 0},
    },
    {
        a       => 0,
        b       => '',
        name    => '0_vs_empty_string',
        diff    => {N => '',O => 0},
    },
    {
        a       => 1,
        b       => -1,
        name    => '1_vs_-1',
        diff    => {N => -1,O => 1},
    },
    {
        a       => 1,
        b       => 1.0,
        name    => '1_vs_1.0',
        diff    => {U => 1},
    },
    {
        a       => 1,
        b       => '1',
        name    => '1_vs_1_as_string',
        diff    => {N => '1',O => 1},
    },
    {
        a       => 1.0,
        b       => '1.0',
        name    => '1.0_vs_1.0_as_string',
        diff    => {N => '1.0',O => 1},
    },
);

run_batch_tests(@TESTS);

done_testing();
