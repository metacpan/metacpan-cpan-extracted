#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;
use Test::Sort::Sub;
use Test::Warnings;

sort_sub_ok(
    subname   => 'data_struct_by_data_cmp',
    input     => [[1,2,3], undef, [6], [4,5]],
    output    => [undef, [1,2,3], [4,5], [6]],
);

done_testing;
