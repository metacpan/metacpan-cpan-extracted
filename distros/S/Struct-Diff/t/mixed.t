#!perl -T

use strict;
use warnings FATAL => 'all';

use Test::More;

use lib "t";
use _common;

my @TESTS = (
    {
        a       => {one => [{two => {three => [ 7, 4 ]}}, 8 ]},
        b       => {one => [{two => {three => [ 7, 3 ]}}, 8 ]},
        name    => 'nested_mixed_structures',
        diff    => {
            D => {one => {D => [{D => {two => {D => {three => {D => [{U => 7},{N => 3,O => 4}]}}}}},{U => 8}]}}},
    },
    {
        a       => {one => [{two => {three => [ 7, 4 ]}}, 8 ]},
        b       => {one => [{two => {three => [ 7, 3 ]}}, 8 ]},
        name    => 'nested_mixed_structures_noOU',
        diff    => {D => {one => {D => [{D => {two => {D => {three => {D => [{I => 1,N => 3}]}}}}}]}}},
        opts    => {noO => 1, noU => 1},
    },
);

run_batch_tests(@TESTS);

done_testing();
