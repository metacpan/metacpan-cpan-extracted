#!/usr/bin/perl
use SimpleR::Reshape;

merge_file( 
    'small.csv', 
    'big.csv', 
    merge_file => "big.merge.csv", 
    by_x => [ 1 ], 
    value_x => [0, 2], 
    by_y => [ 0 ], 
    value_y => [ 0, 1, 2, 3 ], 
);

