#!/usr/bin/perl
use utf8;
use SimpleR::Stat;
use Test::More ;
use Data::Dump qw/dump/;

    my $r = calc_compare_rate(4, 7);
    dump($r);

    my ($r2, $diff) = calc_compare_rate(4, 7);
    dump($r2, $diff);

done_testing;
