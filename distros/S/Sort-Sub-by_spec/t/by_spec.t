#!perl

use 5.010;
use strict;
use warnings;
use Test::More 0.98;
use Test::Sort::Sub;

sort_sub_ok(
    subname   => 'by_spec',
    args      => {spec => [
        qr/[13579]\z/ => sub { $_[0] <=> $_[1] },
        4, 2, 42,
        sub { $_[0] % 2 == 0 } => sub { $_[1] <=> $_[0] },
    ]},
    input     => [1..15,42],
    output    => [1,3,5,7,9,11,13,15,  4,2,42,   14,12,10,8,6],
    #output_i  => [qw/a c e b d f g h/],
    #output_ir => [qw/h g f d b e c a/],
);

done_testing;
