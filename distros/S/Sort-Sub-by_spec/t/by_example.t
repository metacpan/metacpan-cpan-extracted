#!perl

use 5.010;
use strict;
use warnings;
use Test::More 0.98;
use Test::Sort::Sub;

sort_sub_ok(
    subname   => 'by_example',
    args      => {example => 'a,c,e,b,d'},
    input     => [qw/a b c d e f g h/],
    output    => [qw/a c e b d f g h/],
    output_i  => [qw/a c e b d f g h/],
    #output_ir => [qw/h g f d b e c a/],
);

done_testing;
