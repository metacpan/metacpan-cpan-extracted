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
5  3  0  .  7  0  0  .  .
6  0  .  1  9  5  0  .  0
0  9  8  .  .  .  .  6  0
8  0  0  0  6  0  .  .  3
4  .  0  8  .  3  0  .  1
7  0  .  .  2  0  .  0  6
0  6  .  .  0  .  2  8  0
.  0  .  4  1  9  .  0  5
0  .  .  0  8  .  0  7  9
--

my $sudoku = Regexp::Sudoku:: -> new -> init (size  => 9,
                                              clues => $test);

my $exp_clues = {};
my @rows = split /\n/ => $test;
for my $r (keys @rows) {
    my @row = split /\s+/ => $rows [$r];
    for my $c (keys @row) {
        my $exp_val = $row [$c];
        my $cell    = "R" . ($r + 1) . "C" . ($c + 1);
        my $got_val = $sudoku -> clue ($cell);
        if ($exp_val && $exp_val ne '.') {
            $$exp_clues {$cell} = $exp_val;
            is  $got_val, $exp_val, "Clue for cell $cell";
        }
        else {
            ok !$got_val, "No clue for cell $cell";
        }
    }
}

is_deeply $sudoku -> clues, $exp_clues, "All clues";

Test::NoWarnings::had_no_warnings () if $r;

done_testing;
