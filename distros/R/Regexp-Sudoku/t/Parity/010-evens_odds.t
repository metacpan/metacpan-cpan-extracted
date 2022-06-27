#!/usr/bin/perl

use 5.028;

use strict;
use warnings;
no  warnings 'syntax';

use lib qw [lib ../lib ../../lib];

use Test::More 0.88;

our $r = eval "require Test::NoWarnings; 1";

use Regexp::Sudoku;

my @tests = (
    [{},           "2468",              "13579",              "Default"],
    [{size =>  4}, "24",                "13",                 "Small size"],
    [{size =>  9}, "2468",              "13579",              "Default size"],
    [{size => 16}, "2468ACEG",          "13579BDF",           "Large size"],
    [{size => 35}, "2468ACEGIKMOQSUWY", "13579BDFHJLNPRTVXZ", "Max size"],
);


foreach my $test (@tests) {
    my ($args, $exp_e, $exp_o, $name) = @$test;

    my @exp_e  = split // => $exp_e;
    my @exp_o  = split // => $exp_o;

    my $sudoku = Regexp::Sudoku:: -> new -> init (%$args);
    subtest "$name" => sub {
        is         $sudoku -> evens,    $exp_e,   "evens in scalar context";
        is_deeply [$sudoku -> evens],  \@exp_e,   "evens in list context";
        is         $sudoku -> odds,     $exp_o,   "odds in scalar context";
        is_deeply [$sudoku -> odds],   \@exp_o,   "odds in list context";
    };
}

Test::NoWarnings::had_no_warnings () if $r;

done_testing;
