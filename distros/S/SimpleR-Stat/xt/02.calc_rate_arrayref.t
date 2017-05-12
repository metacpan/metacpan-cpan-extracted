#!/usr/bin/perl
use utf8;
use SimpleR::Stat;
use Test::More ;
use Data::Dump qw/dump/;

    my @data = (3, 4, 1);
    my $r = calc_rate_arrayref(\@data);
    dump($r);
    #$r:[0.375, 0.5, 0.125]

done_testing;

