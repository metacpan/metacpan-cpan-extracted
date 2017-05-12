#!/usr/bin/perl

package main;
use strict;
use warnings;
use FindBin qw($Bin);
use lib ("$Bin/../..", "$Bin/../../blib/arch", "$Bin/../../blib/lib");
use Imager;
use SDLx::Tween;

my $size = 18;
my @names = qw(
        linear
        p2_in     p3_in     p4_in     p5_in     exponential_in     circular_in      sine_in      bounce_in     elastic_in     back_in     
        p2_out    p3_out    p4_out    p5_out    exponential_out    circular_out     sine_out     bounce_out    elastic_out    back_out    
        p2_in_out p3_in_out p4_in_out p5_in_out exponential_in_out circular_in_out  sine_in_out  bounce_in_out elastic_in_out back_in_out 
);

my $black = Imager::Color->new('#000000');
my $gray  = Imager::Color->new('#666666');
my $white = Imager::Color->new('#FFFFFF');

my @images;
for my $name (@names) {
    my $img   = Imager->new(xsize => $size, ysize => $size);
    my $val   = [0];
    my $tween = SDLx::Tween->new(
        duration => 1_000 * $size,
        from     => [0],
        to       => [$size],
        on       => $val,
        ease     => $name,
    );
    $tween->start(0);
    $img->box(filled => 1, color => $white);
    my $last_xy = [0, $size];
    for my $x (0..($size-1)) {
        $tween->tick($x * 1_000);
        my ($y) = @$val;
        $y = $size - $y - 1;
        $img->line(
            x1    => $last_xy->[0], y1 => $last_xy->[1],
            x2    => $x           , y2 => $y,
            color => $black       , aa => 1,
        );
        $last_xy = [$x, $y];
    }
    push @images, $img;
}

my $img = Imager->new(xsize => $size, ysize => ($size + 1) * @names + 1);
my $y = 1;
for my $sub_img (@images) {
    $img->paste(left => 0, top => $y, img => $sub_img);
    $y += $size + 1;
}
$img->write(file => "$Bin/easing_functions_chart.png") || die $img->errstr;
