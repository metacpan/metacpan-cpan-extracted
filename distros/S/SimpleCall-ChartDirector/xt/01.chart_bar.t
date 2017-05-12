#!/usr/bin/perl
use utf8;
use lib 'd:/copy/save/windows/chart_director';
use lib '../lib';
use SimpleCall::ChartDirector;

chart_bar([1, 2, 3], 
    file=> '01.chart_bar.png', 
    title => '测试一二', 
    label => [ '测试', '一二', '事情'] , 
    width => 800, 
    height => 330, 
    plot_area => [ 75, 70, 600, 200 ], 
    title_font_size => 12, 
    color => [ qw/Yellow Green Red1/ ], 
);

chart_bar([1, 2, 3], 
    file=> '02.chart_bar_horizontal.png', 
    is_horizontal => 1, 
    title => '测试一二', 
    label => [ '测试', '一二', '事情'] , 
    width => 800, 
    height => 330, 
    plot_area => [ 75, 70, 600, 200 ], 
    title_font_size => 12, 
    color => [ qw/Yellow Green Red1/ ], 
);
