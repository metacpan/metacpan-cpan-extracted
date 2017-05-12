#!/usr/bin/perl
use utf8;
use lib '../lib';
use SimpleR::Reshape;
use Test::More ;
use Data::Dump qw/dump/;

my $src_file = '06.split_file.log';

split_file($src_file, id => [ 0 ] ,
    # sep => ',', 
    # split_file => '06.test.log', 
);

split_file($src_file, line_cnt => 400);

done_testing;
