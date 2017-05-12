#!/usr/bin/perl
use utf8;
use SimpleCall::ChartDirector;

chart_scatter(
    [
        [
            [ 10,  15,  6,  12,  14,  8,   13,  13,  16,  12,  10.5 ],
            [ 130, 150, 80, 110, 110, 105, 130, 115, 170, 125, 125 ],
        ],
        [
            [ 6,  12, 4,  3.5, 7,  8,  9,  10, 12,  11,  8 ],
            [ 65, 80, 40, 45,  70, 80, 80, 90, 100, 105, 60 ],
        ],
    ],
    file            => '10.chart_scatter.png',
    title           => '测试一二',
    label           => [ 1 .. 20 ],
    legend          => [ 'aa', 'bb' ],
    width           => 1000,
    height          => 320,
    plot_area       => [ 75, 70, 800, 200 ],
    title_font_size => 12,
    color           => [qw/Yellow Green Red1/],

    #图例
    with_legend        => 1,
    legend_pos_x       => 320,
    legend_pos_y       => 35,
    legend_is_vertical => 0,

    #Y轴坐标刻度
    #y_tick_density => 1,

    #Y轴取值范围
    #y_axis_lower_limit => 0,
    #y_axis_upper_limit => 10,
);
