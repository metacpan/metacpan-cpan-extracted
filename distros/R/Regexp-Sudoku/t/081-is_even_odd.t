#!/usr/bin/perl

use 5.028;

use strict;
use warnings;
no  warnings 'syntax';

use lib qw [lib ../lib];

use Test::More 0.88;

our $r = eval "require Test::NoWarnings; 1";

use Regexp::Sudoku;

my $test = << '--';  # Does not have to have a solution
5  3  e  e  7  o  o  e  e
6  o  e  1  9  5  o  e  o
o  9  8  e  e  e  e  6  o
8  o  o  o  6  o  e  e  3
4  e  o  8  e  3  o  e  1
7  o  e  e  2  o  e  o  6
o  6  e  e  o  e  2  8  o
e  o  e  4  1  9  e  o  5
o  e  e  o  8  e  o  7  9
--

my $sudoku = Regexp::Sudoku:: -> new -> init (size  => 9,
                                              clues => $test);

my $exp_clues = {};
my @rows = split /\n/ => $test;
for my $r (keys @rows) {
    my @row = split /\s+/ => $rows [$r];
    for my $c (keys @row) {
        my $exp_val  = $row [$c];
        my $cell     = "R" . ($r + 1) . "C" . ($c + 1);
        my $got_even = $sudoku -> is_even ($cell);
        my $got_odd  = $sudoku -> is_odd  ($cell);
        if ($exp_val eq 'e') {
            ok  $got_even, "$cell is even";
            ok !$got_odd,  "$cell is not odd";
        }
        elsif ($exp_val eq 'o') {
            ok !$got_even, "$cell is not even";
            ok  $got_odd,  "$cell is odd";
        }
        else {
            ok !$got_even, "$cell is not even";
            ok !$got_odd,  "$cell is not odd";
        }
    }
}

Test::NoWarnings::had_no_warnings () if $r;

done_testing;
