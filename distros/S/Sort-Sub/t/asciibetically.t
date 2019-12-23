#!perl

use 5.010;
use strict;
use warnings;

use Test::More 0.98;
use Test::Sort::Sub;

sort_sub_ok(
    subname   => 'asciibetically',
    input     => [qw(a C B d 2 1 10)],
    output    => [qw/1 10 2 B C a d/],
    output_i  => [qw/1 10 2 a B C d/],
    output_ir => [qw/d C B a 2 10 1/],
);

done_testing;
