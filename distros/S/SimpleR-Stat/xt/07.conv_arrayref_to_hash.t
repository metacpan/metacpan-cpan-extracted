#!/usr/bin/perl
use utf8;
use SimpleR::Stat;
use Test::More ;
use Data::Dump qw/dump/;

my $data=[ ['a','b',3],['e','f',6], ['a','f',9]];
my $r = conv_arrayref_to_hash($data, [ 0, 1 ], 2);
# $r =  { a => { b => 3, f => 9 }, e => { f => 6 } },

dump($r);

done_testing;
