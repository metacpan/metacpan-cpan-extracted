#!perl -T

use strict;
use warnings FATAL => 'all';

use Test::More;

use lib "t";
use _common;

my @TESTS = (
    {
        a       => {},
        name    => 'error_patch_structure_does_not_match',
        diff    => {D => [{A => 0}]},
        error_patch => 'structure does not match',
        skip_diff => 1,
    },
);

run_batch_tests(@TESTS);

done_testing();
