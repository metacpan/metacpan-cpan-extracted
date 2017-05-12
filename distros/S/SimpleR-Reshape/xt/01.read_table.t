#!/usr/bin/perl
use utf8;
use lib '../lib';
use SimpleR::Reshape;
use Test::More ;
use Data::Dump qw/dump/;

my $r = read_table(
    'reshape_src.csv', 
    skip_head=>1, 
    conv_sub => sub { [ "$_[0][0] $_[0][1]", $_[0][2], $_[0][3] ] }, 

    write_file => '01.read_table.csv', 
    #skip_sub => sub { $_[0][3]<200 }, 
    #return_arrayref => 1, 
    #sep=>',', 
    #charset=>'utf8', 
);
#dump($r);

done_testing;
