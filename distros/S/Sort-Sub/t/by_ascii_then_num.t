#!perl

use 5.010;
use strict;
use warnings;

use Test::More 0.98;
use Test::Sort::Sub;

sort_sub_ok(
    subname   => 'by_ascii_then_num',
    input     => [qw(1 2 -3 a B C d)],
    output    => [qw/B C a d -3 1 2/],
    output_i  => [qw/a B C d -3 1 2/],
    output_ir => [qw/2 1 -3 d C B a/],
);

done_testing;
