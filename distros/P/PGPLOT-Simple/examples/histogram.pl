#!/usr/bin/perl -w
use strict;
$|++;

use PGPLOT::Simple qw(:essential set_color_representation :pgplot);

die "Must provide a filename.\n" unless @ARGV;

my $filename = shift;
chomp $filename;

unless ( $filename =~ /\.ps$/ ) {
    $filename .= ".ps";
}
 
set_begin({
    file => "$filename/CPS",
});
 
my @a=();
for (1..500) {
    $a[$_] = $_ * rand 1000 / 20;
}

set_color_representation({
    code  =>  20,
    red   => 0.1,
    green => 0.4,
    blue  => 0.2,
});

draw_histogram({
    data =>    \@a,
    flag =>      0,
    min  =>   0.00,
    max  => 300.00,
    nbin =>     25,
    color =>    20,
    width =>     2,
    });

write_label({

    title  => 'A Simple Graph Using PGPLOT::Simple',
    color  => 'Blue',
    font   => 'Italic',
});


pgend;
