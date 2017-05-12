#!/usr/bin/perl
use utf8;
use lib '../lib';
use SimpleR::Reshape;
use Test::More ;
use Data::Dump qw/dump/;

my $r = melt('reshape_src.csv',
        #sep=>',', 
        charset => 'utf8', 
        skip_head => 1, 
        #skip_sub => sub { $_[0][3]<1000 }, 

        names => [ qw/day hour state cnt rank/ ], 
        id => [ 0, 1, 2 ],
        measure => [3, 4], 
        #measure_names => [qw/.../], 

        write_head => [ qw/day hour state key value/ ], 
        return_arrayref => 1, 
        melt_file => '02.melt.1.csv',
    );

    melt('reshape_src.csv',
        skip_head => 1, 

        #names => [ qw/day hour state cnt rank/ ], 
        id => [ sub { "$_[0][0]d $_[0][1]h" } , 2 , 'test' ],
        measure => [ 3, 4, sub { $_[0][3] * $_[0][4] } ], 
        measure_names => [qw/cnt rank cxr/], 

        write_head => [ qw/dayhour state somehead key value/ ], 
        melt_file => '02.melt.2.csv',
    );
dump($r);

done_testing;

