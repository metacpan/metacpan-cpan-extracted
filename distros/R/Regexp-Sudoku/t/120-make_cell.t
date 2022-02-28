#!/usr/bin/perl

use 5.028;

use strict;
use warnings;
no  warnings 'syntax';

use lib qw [lib ../lib];

use Test::More 0.88;

our $r = eval "require Test::NoWarnings; 1";

use Regexp::Sudoku;

my $SENTINEL = "\n";

my $test = << '--';  # Does not have to have a solution
5  3  e  o  7  e  o  e  o
6  e  o  1  9  5  e  o  e
e  9  8  e  e  e  e  6  e
8  0  0  0  6  0  0  0  3
4  0  0  8  0  3  0  0  1
7  0  0  0  2  0  0  0  6
o  6  o  o  o  o  2  8  o
e  o  e  4  1  9  o  e  5
o  e  o  e  8  o  e  7  9
--

my $sudoku = Regexp::Sudoku:: -> new -> init (size  => 9,
                                              clues => $test);

my @rows = split /\n/ => $test;
for my $r (keys @rows) {
    my @row = split /\s+/ => $rows [$r];
    for my $c (keys @row) {
        my $value   = $row [$c];
        my $cell    = "R" . ($r + 1) . "C" . ($c + 1);
        my ($got_str, $got_pat) = $sudoku -> make_cell ($cell);
        my ($exp_str, $exp_pat, $name);

        if (!$value) {
            $exp_str = "123456789"                   . $SENTINEL;
            $exp_pat = "[1-9]*(?<$cell>[1-9])[1-9]*" . $SENTINEL;
            $name    = "Cell $cell (empty)";
        }
        elsif ($value eq 'e') {
            $exp_str = "2468"                        . $SENTINEL;
            $exp_pat = "[1-9]*(?<$cell>[1-9])[1-9]*" . $SENTINEL;
            $name    = "Cell $cell (even)";
        }
        elsif ($value eq 'o') {
            $exp_str = "13579"                       . $SENTINEL;
            $exp_pat = "[1-9]*(?<$cell>[1-9])[1-9]*" . $SENTINEL;
            $name    = "Cell $cell (odd)";
        }
        else {
            $exp_str = "$value"                      . $SENTINEL;
            $exp_pat = "(?<$cell>$value)"            . $SENTINEL;
            $name    = "Cell $cell (clue)";
        }
        subtest $name => sub {
            is $got_str, $exp_str, "String";
            is $got_pat, $exp_pat, "Pattern";
        }
    }
}

Test::NoWarnings::had_no_warnings () if $r;

done_testing;
