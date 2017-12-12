#!perl -T

use strict;
use warnings FATAL => 'all';

use Test::More;

use lib "t";
use _common;

my $one = sub { return 0 };
my $two;

my @TESTS = (
    {
        a       => $one,
        b       => $one,
        name    => 'same_coderef',
        diff    => {U => $one},
    },
    {
        a       => $one,
        b       => $two = sub { return 0 },
        name    => 'equal_by_code_coderefs',
        diff    => {U => $one},
        skip_patch => 1 # FIXME
    },
    {
        a       => $one,
        b       => $two = sub { 0 },
        name    => 'same_meaning_but_different_by_code_coderefs',
        diff    => {N => $two,O => $one},
    },
    {
        a       => $one,
        b       => $two = sub { return 1 },
        name    => 'different_by_code_coderefs',
        diff    => {N => $two,O => $one},
    },
);

map { $_->{to_json} = 0 } @TESTS;

run_batch_tests(@TESTS);

done_testing();
