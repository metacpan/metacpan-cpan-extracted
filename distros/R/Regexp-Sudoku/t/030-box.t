#!/usr/bin/perl

use 5.028;

use strict;
use warnings;
no  warnings 'syntax';

use lib qw [lib ../lib];

use Test::More 0.88;

our $r = eval "require Test::NoWarnings; 1";

use Regexp::Sudoku;

my @tests = (
    [{},            3,  3,  "Default values"],
    [{size =>  4},  2,  2,  "Small size"],
    [{size =>  6},  3,  2,  "Not a square"],
    [{size =>  9},  3,  3,  "Default size"],
    [{size => 12},  4,  3,  "Larger size"],
    [{size => 17}, 17,  1,  "Prime size"],
);


foreach my $test (@tests) {
    my ($args, $exp_w, $exp_h, $name) = @$test;

    my $sudoku = Regexp::Sudoku:: -> new -> init (%$args);
    is $sudoku -> box_width,  $exp_w, "$name (width)";
    is $sudoku -> box_height, $exp_h, "$name (height)";
}

Test::NoWarnings::had_no_warnings () if $r;

done_testing;
