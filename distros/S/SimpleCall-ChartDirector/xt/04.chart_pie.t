#!/usr/bin/perl
use utf8;
use SimpleCall::ChartDirector;

chart_pie([1, 2, 3], 
    file=> '04.chart_pie.png', 
    title => '测试一二', 
    label => [ '测试', '一二', '事情'] , 
    width => 700, 
    height => 500, 
    pie_size =>  [ 350, 290, 180 ],
    title_font_size => 12, 
    color => [ qw/Yellow Green Red1/ ], 

    #图例
    with_legend => 1, 
    legend_pos_x => 265, 
    legend_pos_y => 55, 
    legend_is_vertical => 0, 

    #旋转角度
    start_angle => 30,  

    #饼图各部分的标签
    label_format => "{label}\n{value}, {percent}%", 
    label_pos => 20, 

    #拉出一条线指向一块饼
    label_side_layout => 1, 
);
