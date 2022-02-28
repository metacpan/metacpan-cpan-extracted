#!/usr/bin/perl

use 5.028;

use strict;
use warnings;
no  warnings 'syntax';

use lib qw [lib ../lib];

use Test::More 0.88;
use Test::Exception;

our $r = eval "require Test::NoWarnings; 1";

use Regexp::Sudoku;


my @tests = (
    [{},            9, "Handle default size"],
    [{size =>  4},  4, "Small size"],
    [{size =>  9},  9, "Normal size"],
    [{size => 16}, 16, "Large size"],
    [{size => 35}, 35, "Largest size"],
);

foreach my $test (@tests) {
    my ($args, $exp, $name) = @$test;

    my $sudoku = Regexp::Sudoku:: -> new -> init (%$args);
    is $sudoku -> size, $exp, $name;
}

throws_ok {
    my $sudoku = Regexp::Sudoku:: -> new -> init (size => 36);
}  qr /Size should not exceed 35/, "Dies on size too large";

Test::NoWarnings::had_no_warnings () if $r;

done_testing;
