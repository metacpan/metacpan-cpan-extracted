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
    x_min => 0,
    x_max => 50,
    y_min => 0,
    y_max => 10,
});
 
draw_function('x', {
        fy    => sub{ sqrt $_[0] },
        num   =>    500,
        min   =>      0,
        max   =>     50,
        color => 'Blue',
        width =>      7,
    });

draw_function('xy', {
        fy    => sub{ 3 * cos $_[0] },
        fx    => sub{ 5 * sin $_[0] },
        num   =>         500,
        min   =>          10,
        max   =>         100,
        width =>           7,
        color => 'GreenCyan',
    });

write_label({
    title  => 'A Simple Graph Using PGPLOT::Simple',
    color  => 'Blue',
    font   => 'Italic',
});

set_end();
