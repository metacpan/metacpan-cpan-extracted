#!/usr/bin/perl
use utf8;
use SimpleR::Stat;
use Test::More ;

use Data::Dump qw/dump/;

my @data = (3, 4, 1);
my $r = calc_percent_arrayref(\@data);
dump($r);
#["37.50%", "50.00%", "12.50%"]

done_testing;

