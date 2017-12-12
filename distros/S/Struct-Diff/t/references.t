#!perl -T

use strict;
use warnings FATAL => 'all';

use Test::More;

use lib "t";
use _common;

my ($one, $two) = (0, 0);
my @TESTS = (
    {
        a       => \$one,
        b       => \$one,
        name    => 'same_scalar_reference',
        diff    => {U => \$one},
    },
    {
        a       => \$one,
        b       => \$two,
        name    => 'different_refs_but_equal_data',
        diff    => {U => \0},
    },
    {
        a       => \$one,
        b       => \'two',
        name    => 'different_refs_different_data',
        diff    => {N => \'two',O => \$one},
    },
    {
        a       => \$one,
        b       => $one,
        name    => 'scalar_ref_vs_scalar',
        diff    => {N => $one,O => \$one},
    },
    {
        a       => \$one,
        b       => \\$one,
        name    => 'scalar_ref_vs_refref',
        diff    => {N => \\$one,O => \$one},
    },
    {
        a       => [ \$one ],
        b       => [ \'two' ],
        name    => 'nested_different_refs_different_data',
        diff    => {D => [{N => \'two',O => \$one}]},
    },
    {
        a       => [ \$one ],
        b       => [ \\$one ],
        name    => 'nested_scalar_ref_vs_refref',
        diff    => {D => [{N => \\$one,O => \$one}]},
    },
    {
        a       => {x => \{y => \$one}},
        b       => {x => \{y => \$one}},
        name    => 'nested_references',
        diff    => {U => {x => \{y => \$one}}},
    },
);

map { $_->{to_json} = 0 } @TESTS;

run_batch_tests(@TESTS);

done_testing();
