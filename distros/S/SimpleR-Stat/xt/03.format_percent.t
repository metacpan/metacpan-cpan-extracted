#!/usr/bin/perl
use utf8;
use SimpleR::Stat;
use Test::More ;
use Data::Dump qw/dump/;

my $r = format_percent('0.675', '%.2f%%');
dump($r);

done_testing;
