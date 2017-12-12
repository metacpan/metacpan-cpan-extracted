#!perl -T

use strict;
use warnings FATAL => 'all';

use Test::More;

use lib "t";
use _common;

my @TESTS = (
    {
        a       => '',
        b       => undef,
        name    => 'empty_string_vs_undef',
        diff    => {N => undef,O => ''},
    },
    {
        a       => '',
        b       => 0,
        name    => 'empty_string_vs_0',
        diff    => {N => 0,O => ''}
    },
    {
        a       => 'a',
        b       => 'a',
        name    => 'a_vs_a',
        diff    => {U => 'a'},
    },
    {
        a       => 'a',
        b       => 'b',
        name    => 'a_vs_b',
        diff    => {N => 'b',O => 'a'},
    },
);

run_batch_tests(@TESTS);

done_testing();
