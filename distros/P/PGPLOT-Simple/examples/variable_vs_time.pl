#!/usr/bin/perl -w
use strict;
$|++;

use PGPLOT::Simple qw(:essential);
use YAML;
use List::Util qw(min max);


die "Must provide a filename.\n" unless @ARGV;

my $filename = shift;
chomp $filename;

unless ( $filename =~ /\.ps$/ ) {
    $filename .= ".ps";
}

# Get data back from file
my $select = YAML::LoadFile('select.yaml');

# Load it into our axes arrays
my (@x, @y) = ();
for my $row ( @$select ) {
    push @x, $row->[0];
    push @y, $row->[1];
}

# We make this so that PGPLOT can calculate the X tick labels
my $x_min = min @x;
for my $v (@x) {
    $v = $v - $x_min;
}


my $size  = scalar @x;
$x_min    = min @x;
my $x_max = max @x;
my $y_min = min @y;
my $y_max = max @y;


set_begin({
    file => "$filename/CPS",
});

set_window({
    x_min => $x_min,
    x_max => $x_max,
    y_min => $y_min,
    y_max => $y_max+0.1,
});

set_box();
# See documentation, calling this function without options will give draw the
# X axes as a (DD) HH MM SS axe.

write_label({
    x     => 'Time',
    y     => 'Radians',
    title => "A Plot With A Time Axe",
    font  => 'Roman',
    color => 'Red',
});
    
draw_polyline({
    x        => \@x,
    y        => \@y,
    color    => 'RedMagenta',
    width    =>   4,
});

write_text({
    x          => 800,
    y          => 1.5,
    string     => "PGPLOT Is Great!",
    background => 'BlueMagenta',
    color      => 'Yellow',
    height     => 2.5,
    angle      => 270,
    font       => 'Script',
});

draw_rectangle({
    x1    => 1500,
    x2    => 2000,
    y1    =>  1.2,
    y2    =>  1.5,
    color => 'Orange',
    fill  => 'Hatched',
    width =>    7,
});

draw_error_bars({ 
    y        => [1.2, 1.5, 1.4],
    x1       => [400, 1100, 2500],
    x2       => [500, 1100, 2900],
    color    => 'Red',
    width    => 3,
    terminal => 3,
});

draw_error_bars({ 
    y1       => [1.3],
    y2       => [1.5],
    x        => [2700],
    color    => 'Yellow',
    width    => 2,
    terminal => 2,
});

draw_arrow({
    x1    => 1300,
    x2    => 2000,
    y1    =>  1.1,
    y2    => 1.56,
    color => 'GreenYellow',
    width =>   10,
    arrow_style => {
        fill  => 'Outline',
        angle => 90,
    },
});

set_end();
