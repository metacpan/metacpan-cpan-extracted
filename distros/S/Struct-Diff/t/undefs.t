#!perl -T

use strict;
use warnings FATAL => 'all';

use Test::More;

use lib "t";
use _common;

my @TESTS = (
    {
        a       => undef,
        b       => undef,
        name    => 'undef_vs_undef',
        diff    => {U => undef},
    },
    {
        a       => undef,
        b       => 0,
        name    => 'undef_vs_0',
        diff    => {N => 0,O => undef},
    },
    {
        a       => undef,
        b       => -1,
        name    => 'undef_vs_negative_number',
        diff    => {N => -1,O => undef},
    },
    {
        a       => undef,
        b       => '',
        name    => 'undef_vs_empty_string',
        diff    => {N => '',O => undef},
    },
    {
        a       => undef,
        b       => [],
        name    => 'undef_vs_empty_list',
        diff    => {N => [],O => undef},
    },
    {
        a       => undef,
        b       => {},
        name    => 'undef_vs_empty_hash',
        diff    => {N => {},O => undef},
    },
    {
        a       => undef,
        b       => {},
        name    => 'undef_vs_empty_hash_noNO',
        diff    => {},
        opts    => {noN => 1, noO => 1},
    },
    {
        a       => undef,
        b       => bless({}, 'SomeThing'),
        name    => 'undef_vs_blessed',
        diff    => {N => bless({}, 'SomeThing'),O => undef},
        to_json => 0,
    },
);

run_batch_tests(@TESTS);

done_testing();
