#!/usr/bin/perl -w
use strict;
$|++;

use PGPLOT::Simple qw(:essential);

die "Must provide a filename.\n" unless @ARGV;

my $filename = shift;
chomp $filename;

unless ( $filename =~ /\.ps$/ ) {
    $filename .= ".ps";
}

set_begin({
    file => "$filename/CPS",
});
 
set_environment({
    x_min   =>  0,
    x_max   =>  50,
    y_min   =>  0,
    y_max   =>  10,
    color   =>  'Yellow',
});

write_label({
    title  => 'A Simple Graph Using PGPLOT::Simple',
    color  => 'Blue',
    font   => 'Italic',
});

draw_points({
    x     => [1, 3, 12, 32, 40],
    y     => [1, 5,  5,  3,  9],
    color => 'Blue',
    width => 20,
});

draw_error_bars({
    x        => [20],
    y1       => [4],
    y2       => [6],
    terminal => 10,
    width    => 12.2,
    color    => 'Cyan',
});

set_end();
