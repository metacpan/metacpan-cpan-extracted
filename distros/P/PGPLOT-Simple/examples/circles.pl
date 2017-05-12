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
    x_min   =>   0,
    x_max   =>  10,
    y_min   =>   0,
    y_max   =>  10,
});

write_label({
    title  => 'A Simple Graph Using PGPLOT::Simple',
    color  => 'Blue',
    font   => 'Italic',
});

draw_circle({
    x       => 4.5,
    y       => 4,
    radius  => 3,
    width   => 4,
    color   => 'Yellow',
});

draw_circle({
    x       => 4.5,
    y       => 4,
    radius  => 1,
    width   => 4,
});


set_end();
