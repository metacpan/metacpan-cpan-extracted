#!/usr/bin/perl
use utf8;
use SimpleR::Reshape;
use Test::More ;
use Data::Dump qw/dump/;

my $r = merge( 
    [ [qw/a b 1/], [qw/c d 2/] ], 
    [ [qw/a b 3/], [qw/c d 4/] ], 
    by => [ 0, 1], 
    value => [2], 
);
dump($r);
# $r = [["a", "b", 1, 3], ["c", "d", 2, 4]]


done_testing;
