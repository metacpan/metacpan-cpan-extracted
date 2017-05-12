#!/usr/bin/perl
use utf8;
use lib '../../lib';
use SimpleR::Stat;
use Test::More ;
use Data::Dump qw/dump/;

my $data=[ 'haha', 'xx', 4 , 2, 3, 1, 'heihei'];
my @res = map_arrayref(
    $data, 
    \&calc_rate_arrayref,
    return_arrayref => 1, 
    keep_source => 1, 
    calc_col => [ 2 .. 5 ], 
);

dump(@res);

done_testing;
