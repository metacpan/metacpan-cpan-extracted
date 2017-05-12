#!/usr/bin/perl
use strict;
use warnings;

use SimpleR::Reshape;
use List::AllUtils qw/mesh/;

use lib 'd:/copy/windows/chart_director';
use SimpleCall::ChartDirector;

use utf8;

my ( $src, $predict_type, $cnt ) = @ARGV;

$src ||= 'iris_test.csv.predict.csv';
$predict_type ||= 0;
$cnt          ||= '';

my %mem;
read_table(
    $src,
    conv_sub => sub {
        my ($r) = @_;
        my $t = $r->[$predict_type] || 'unknown';
        my $c = $cnt =~ /\d/ ? $r->[$cnt] : 1;

        #print "$predict_type, $cnt , $t, $c\n";
        $mem{$t} += $c;
        return;
    },
    skip_head       => 1,
    return_arrayref => 0,
);

my @mem = sort { $b->[1] <=> $a->[1] } map { [ $_, $mem{$_} ] } keys(%mem);
$cnt ||= 'x';
write_table( \@mem, file => "$src.$predict_type.$cnt.csv" );
chart_type_stat( \@mem, "$src.$predict_type.$cnt.png" );

sub chart_type_stat {
    my ( $rr, $img ) = @_;

    chart_pie(
        [ map { $_->[1] } @$rr ],
        file            => $img,
        title           => 'stat',
        label           => [ map { $_->[0] } @$rr ],
        width           => 900,
        height          => 600,
        pie_size        => [ 400, 290, 180 ],
        title_font_size => 12,

        #color => [ qw/Yellow Green Red1/ ],

        #图例
        with_legend        => 1,
        legend_pos_x       => 265,
        legend_pos_y       => 55,
        legend_is_vertical => 0,

        start_angle => 30,

        label_format => "{label}\n{value}, {percent}%",
        label_pos    => 20,

        label_side_layout => 1,
    );

}
