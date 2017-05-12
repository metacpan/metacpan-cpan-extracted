#!/usr/bin/perl
use utf8;
use lib '../lib';
use SimpleR::Reshape;
use Test::More ;
use Data::Dump qw/dump/;

my $r = cast('02.melt.csv', 
        #sep => ',', 

        #key 有 cnt / rank 两种
        names => [ qw/day hour state key value/ ], 
        id => [ 0, 1, 2 ],
        measure => 3, 
        value => 4, 
        
        reduce_sub => sub { my ($last, $now) = @_; return $last+$now; }, 

        write_head => 1, 

        default_cell_value => 0,

        cast_file => '03.cast.1.csv', 
        return_arrayref => 1, 
    );

    cast('02.melt.csv', 
        sep => ',', 

        #names => [ qw/day hour state key value/ ], #key 有 cnt / rank 两种
        id => [ sub { "$_[0][0] $_[0][1]" }, 2 ],
        id_names => [ qw/dayhour state/ ],
        measure => 3, 
        measure_names => [ qw/rank cnt/ ],
        value => 4, 

        stat_sub => sub { my ($r) = @_; (sort { $b<=> $a } @$r)[0] }, 
        default_cell_value => 0,

        write_head => 1, 
        cast_file => '03.cast.2.csv', 
        return_arrayref => 0, 
    );
#dump($r);

done_testing;




