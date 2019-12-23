#!perl

use 5.010;
use strict;
use warnings;
use Test::More 0.98;
use Test::Sort::Sub;

sort_sub_ok(
    subname   => 'by_perl_function',
    args      => {function => 'length'},
    input     => [qw(aa c bbb)],
    output    => [qw/c aa bbb/],
    output_i  => [qw/c aa bbb/],
    output_ir => [qw/bbb aa c/],
);

done_testing;
