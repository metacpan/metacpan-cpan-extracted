#!/usr/bin/perl
use utf8;
use SimpleCall::ChartDirector;

chart_pyramid([1, 2, 3], 
    file=> '03.chart_pyramid.png', 
    title => '测试一二', 
    label => [ '测试', '一二', '事情'] , 
    width => 460, 
    height => 400, 
    plot_area => [ 210, 190, 150, 300 ],
    title_font_size => 12, 
    color => [ qw/Yellow Green Red1/ ], 
);
