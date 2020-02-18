#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;
use Test::Sort::Sub;
use Test::Warnings;

sort_sub_ok(
    subname   => 'by_dmp',
    input     => [undef, 1, "a", [], {}],
    output    => ["a", 1, [], undef, {}],
);

done_testing;
