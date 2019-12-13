#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;
use Test::Sort::Sub;

sort_sub_ok(
    subname   => 'by_count',
    args      => {pattern=>':'},
    input     => ['a::', 'b:', 'c::::', 'd:::'],
    output    => ['b:', 'a::', 'd:::', 'c::::'],
);

# XXX test arg: ignore_case
# XXX test arg: fixed_string

done_testing;
