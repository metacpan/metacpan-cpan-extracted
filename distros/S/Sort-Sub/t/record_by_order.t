#!perl

use 5.010;
use strict;
use warnings;
use Test::More 0.98;
use Test::Sort::Sub;

sort_sub_ok(
    subname   => 'record_by_order',
    compares_record => 1,
    input     => [qw(1 -2 3 -4)],
    output    => [qw/1 -2 3 -4/],
    output_i  => [qw/1 -2 3 -4/],
    output_ir => [qw/-4 3 -2 1/],
);

done_testing;
