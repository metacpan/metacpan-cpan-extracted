#!/usr/bin/perl
use utf8;
use SimpleR::Stat;
use Test::More ;
use Data::Dump qw/dump/;

my $data = [  3, 3, 4,  4, 1 ];
my $r = uniq_arrayref($data);
my $cnt = uniq_arrayref_cnt($data); 

dump($r, $cnt);

done_testing;
