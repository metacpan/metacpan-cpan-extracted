#!/usr/bin/perl
use utf8;
use SimpleR::Stat;
use Test::More ;
use Data::Dump qw/dump/;

my $data = [  3, 4, 1 ];
my $sum = sum_arrayref($data);
my $mean = mean_arrayref($data);
my $med = median_arrayref($data);

dump($sum, $mean, $med);

done_testing;
