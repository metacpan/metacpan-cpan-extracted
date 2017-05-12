#!/usr/bin/perl
use utf8;
use SimpleCall::ChartDirector;

chart_percentage_area([[5, 6, 7, 8], [1, 2, 6, 9], [3, 9, 2, 4], ], 
    file=> '12.chart_percentage_area.png', 
    title => '测试一二', 
    label => [ 'day1', 'day3', 'day5', 'day7'] , 
    legend => [ 'aa','bb','cc'] , 
    width => 1000, 
    height => 320, 
    plot_area => [ 75, 70, 800, 200 ],
    title_font_size => 12, 
    color => [ qw/Yellow Green Red1/ ], 

    #图例
    with_legend => 1, 
    legend_pos_x => 320, 
    legend_pos_y => 35, 
    legend_is_vertical => 0, 

#Y轴格式
#例如加一个百分号：'y_label_format'=> '{value}%',
    #y_label_format => '{value}', 

#Y轴坐标刻度
    #y_tick_density => 1, 

#Y轴取值范围
    #y_axis_lower_limit => 0, 
    #y_axis_upper_limit => 10, 
);
