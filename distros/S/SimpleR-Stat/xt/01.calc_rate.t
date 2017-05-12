#!/usr/bin/perl
use utf8;
use SimpleR::Stat;
use Test::More ;
use Data::Dump qw/dump/;

my $r = calc_rate(3, 4);
dump($r);

done_testing;
