#!/usr/bin/perl
use utf8;
use lib '../lib';
use SimpleR::Reshape;
use Test::More ;
use Data::Dump qw/dump/;

my $r = arrange('reshape_src.csv', 
    skip_head => 1, 
    sep=> ',', 
    charset => 'utf8', 

    arrange_sub => sub { 
        $a->[4] <=> $b->[4] or
        $a->[3] <=> $b->[3] 
    }, 
    arrange_file => '07.arrange.csv', 
    return_arrayref => 1, 
    write_head => [ qw/day hour state cnt rank/ ], 
);
dump($r);

done_testing;
