#!/usr/bin/perl
use SimpleR::Reshape::ChartData;
use lib 'd:/copy/save/windows/chart_director';
use SimpleCall::ChartDirector;
use Data::Dump qw/dump/;

my ($r, %opt) = read_chart_data_dim3_horizon('03.dim3_horizon.csv', 
    skip_head=> 1, 
    label => [0], 
    legend => [1 .. 3], 
    names => [ qw/time good normal bad/ ], 
    sep=> ','
);

dump($r, %opt);

#[[1, 4, 3, 7], [3, 2, 2, 9], [4, 2, 3, 8]],
#"legend",
#["bad", "good", "normal"],
#"label",
#["2013-08-01", "2013-08-02", "2013-08-03", "2013-08-04"],

chart_line($r, %opt, 
    'title' => 'test', 
    'file' => '03.dim3_horizon.png', 
    with_legend=>1);
