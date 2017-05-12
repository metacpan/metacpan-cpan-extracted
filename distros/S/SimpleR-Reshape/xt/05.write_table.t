#!/usr/bin/perl
use utf8;
use SimpleR::Reshape;
use Test::More ;
use Data::Dump qw/dump/;

my $d = [ [qw/a b 1/], [qw/c d 2/] ]; 
write_table($d, file=> 'write_table.csv', head => [ 'ka', 'kb', 'cnt']);

done_testing;
