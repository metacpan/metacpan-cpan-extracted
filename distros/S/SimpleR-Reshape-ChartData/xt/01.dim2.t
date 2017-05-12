#!/usr/bin/perl
use SimpleR::Reshape::ChartData;
use SimpleCall::ChartDirector;
use Data::Dump qw/dump/;

my ($r, %opt) = read_chart_data_dim2('01.dim2.csv', 
    skip_head=> 1, 
    label => [0], 
    data => [1], 
    sep=> ','
);

dump($r, %opt);
  #[4, 3, 5],
  #"legend",
  #[
    #"\xE6\x9D\x8E\xE5\xAD\x90",
    #"\xE6\xA1\x83\xE5\xAD\x90",
    #"\xE8\x8B\xB9\xE6\x9E\x9C",
  #],
  #"label",
  #[
    #"\xE6\x9D\x8E\xE5\xAD\x90",
    #"\xE6\xA1\x83\xE5\xAD\x90",
    #"\xE8\x8B\xB9\xE6\x9E\x9C",
  #],
  
chart_horizon_bar($r, %opt, 
    'title' => 'test', 
    'file' => '01.dim2.png', 
);
