#!/usr/bin/perl -w
#
# Test Program for ASCII Plot
# copyright 2007 Les Hall
# Tests the ASCII Plot
#
#

# strict warnings and error checking
use strict;
use warnings;
use Data::Dumper;


# use OOP classes
use ScatterPlot;  # use OOP class to make an ASCII scatter plot

# create OOP objects
my $plot = ScatterPlot->new();  # make a new ASCII_Plot object

# define some example dataset
my $x_size = 40;
my $y_size = 15;
my @xy_points = ([-0.5,0.5],[1,1.5],[-1.5,-1],[-2,-2],[2,2]);

# draw the plot
print "\n";
print "\n";
print "HTML call:\n";
$plot->draw(\@xy_points, $x_size, $y_size, 'x_axis', 'y_axis', 'o', 'html');
print "\n";
print "\n";
print "text call\n";
$plot->draw(\@xy_points, $x_size, $y_size, 'x_axis', 'y_axis', 'o', 'text');
print "\n";
print "\n";
print "Result with no input parameters:\n";
$plot->draw();


