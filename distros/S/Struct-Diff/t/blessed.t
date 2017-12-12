#!perl -T

use strict;
use warnings FATAL => 'all';

use Test::More;

use lib "t";
use _common;

my $one = bless({}, 'SomeThing');
my $two;

my @TESTS = (
    {
        a       => $one,
        b       => $one,
        name    => 'same_blessed_ref',
        diff    => {U => $one},
    },
    {
        a       => $one,
        b       => $two = bless({}, 'SomeThing'),
        name    => 'equal_blessed_different_refs',
        diff    => {U => $one},
    },
    {
        a       => $one,
        b       => $two = bless([], 'SomeThing'),
        name    => 'same_classname_but_different_data',
        diff    => {N => $two,O => $one},
    },
    {
        a       => $one,
        b       => $two = bless({}, 'AnotherThing'),
        name    => 'same_data_but_different_classname',
        diff    => {N => $two,O => $one},
    },
);

map { $_->{to_json} = 0 } @TESTS;

run_batch_tests(@TESTS);

done_testing();
