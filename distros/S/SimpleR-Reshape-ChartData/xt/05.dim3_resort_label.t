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

chart_percentage_bar($r, %opt, 
    'title' => 'test', 
    'file' => '05.dim3_resort_label.nosort.png', 
     with_legend=>1
 );

 #---------------

 ($r, %opt) = read_chart_data_dim3('02.dim3.csv', 
    skip_head=> 1, 
    label => [0], 
    legend => [1], 
    legend_sort => [qw/优 良 差/], 
    data => [2], 
    sep=> ',', 
    charset => 'utf8', 

    resort_label_by_chart_data_map => sub { 
        my ($r) = @_; 
        my ($g, $n, $b) = @$r;
        my $all = $g+$n+$b;
        return [ $b/$all, $n/$all ]
    }, 
    resort_label_by_chart_data_sort => sub {
        my ($x, $y) = @_;
        ($x->[0] <=> $y->[0]) or ($x->[1] <=> $y->[1])
    }, 
);

chart_percentage_bar($r, %opt, 
    'title' => 'test', 
    'file' => '05.dim3_resort_label.sort.png', 
     with_legend=>1
 );

