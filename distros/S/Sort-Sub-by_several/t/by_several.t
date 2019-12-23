#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;
use Test::Sort::Sub;

sort_sub_ok(
    subname   => 'by_several',
    args      => {first => 'by_length<r>', second => 'numerically'},
    input     => [qw/1 0 3 4 11 7 111 222 333 290 2222 1111/],
    output    => [qw/1111 2222 111 222 290 333 11 0 1 3 4 7/],
    output_r  => [qw/7 4 3 1 0 11 333 290 222 111 2222 1111/],
);

sort_sub_ok(
    subname   => 'by_several',
    args      => {first => 'by_length<r>', second => 'numerically<r>'},
    input     => [qw/1 0 3 4 11 7 111 222 333 290 2222 1111/],
    output    => [qw/2222 1111 333 290 222 111 11 7 4 3 1 0/],
    output_r  => [qw/0 1 3 4 7 11 111 222 290 333 1111 2222/],
);

done_testing;
