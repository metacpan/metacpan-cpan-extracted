#!perl

use 5.010;
use strict;
use warnings;
use Test::More 0.98;
use Test::Sort::Sub;

# string code
sort_sub_ok(
    subname   => 'by_perl_code',
    args      => {code => 'length $_[0] <=> length $_[1]'},
    input     => [qw(aa c bbb)],
    output    => [qw/c aa bbb/],
    output_i  => [qw/c aa bbb/],
    output_ir => [qw/bbb aa c/],
);

# compiled code
sort_sub_ok(
    subname   => 'by_perl_code',
    args      => {code => sub { length $_[0] <=> length $_[1] }},
    input     => [qw(aa c bbb)],
    output    => [qw/c aa bbb/],
    output_i  => [qw/c aa bbb/],
    output_ir => [qw/bbb aa c/],
);

done_testing;
