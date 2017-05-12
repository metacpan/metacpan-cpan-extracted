#!/usr/bin/perl
use lib 'd:/copy/save/windows/chart_director/';
use lib '../lib';
use SimpleR::Reshape::ChartData;
use SimpleCall::ChartDirector;
use Data::Dump qw/dump/;
use utf8;

my ($r, %opt) = read_chart_data_dim3_scatter('04.dim3_scatter.csv', 
    skip_head=> 1, 
    label => [1], 
    legend => [0], 
    data => [2], 
    label_sort => [  1 .. 20 ], 
    #legend_sort => [ '类', '型' ], 

    sep=> ',', 
    charset => 'utf8', 
);

#(
  #[
    #[
      #[6, 11, 7, 9, 12, 8, 4, 3.5, 10],
      #[65, 105, 70, 80, 100, 60, 40, 45, 90],
    #],
    #[
      #[6, 10.5, 12, 14, 15, 8, 10, 13, 16],
      #[80, 125, 125, 110, 150, 105, 130, 115, 170],
    #],
  #],
  #"legend",
  #["\x{578B}", "\x{7C7B}"],
  #"label",
  #[1 .. 20],
#)
  
chart_scatter($r, %opt, 
    'title' => 'test', 
    'file' => '04.dim3_scatter.png', 
     with_legend=>1, 
    legend_pos_x       => 320,
    legend_pos_y       => 35,
    legend_is_vertical => 0,
 );
