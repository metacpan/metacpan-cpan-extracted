#!/usr/bin/perl
use SimpleR::Reshape::ChartData;
use SimpleCall::ChartDirector;
use Data::Dump qw/dump/;
use utf8;

my ($r, %opt) = read_chart_data_dim3('02.dim3.csv', 
    skip_head=> 1, 
    label => [0], 
    legend => [1], 
    data => [2], 
    sep=> ',', 
    charset => 'utf8', 
);

dump($r, %opt);
#[[3, 2], [0, 1], [3, 0]],
#"legend",
#["\xE4\xBC\x98", "\xE5\xB7\xAE", "\xE8\x89\xAF"],
#"label",
#["\xE7\x94\xB5\xE4\xBF\xA1", "\xE8\x81\x94\xE9\x80\x9A"],
  
chart_stacked_bar($r, %opt, 
    'title' => 'test', 
    'file' => '02.dim3.png', 
     with_legend=>1);
