#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;
use Test::Sort::Sub;

sort_sub_ok(
    subname   => 'numerically',
    input     => [qw(1 2 -3)],
    output    => [qw/-3 1 2/],
    output_r  => [qw/2 1 -3/],
    output_ir => [qw/2 1 -3/],
);

done_testing;
