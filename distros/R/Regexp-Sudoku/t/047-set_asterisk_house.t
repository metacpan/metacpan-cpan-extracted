#!/usr/bin/perl

use 5.028;

use strict;
use warnings;
no  warnings 'syntax';

use lib qw [lib ../lib];

use Test::More 0.88;

our $r = eval "require Test::NoWarnings; 1";

use Regexp::Sudoku;

my $size = 9;

my $sudoku = Regexp::Sudoku:: -> new -> init -> set_asterisk_house;

my @exp_cells = sort map {"R" . $$_ [0] . "C" . $$_ [1]} [3, 3], [2, 5], [3, 7],
                                                         [5, 2], [5, 5], [5, 8],
                                                         [7, 3], [8, 5], [7, 7];
my %exp_cells = map {$_ => 1} @exp_cells;
my @got_cells = sort $sudoku -> house2cells ("AS");

is_deeply \@got_cells, \@exp_cells, "Asterisk cells";

for my $r (1 .. $size) {
    for my $c (1 .. $size) {
        my $cell = "R${r}C${c}";
        my %got_houses = map {$_ => 1} $sudoku -> cell2houses ($cell);
        ok !($exp_cells {$cell} xor $got_houses {"AS"}),
             $exp_cells {$cell} ?  "Cell $cell in the asterisk"
                                :  "Cell $cell not in the asterisk";
    }
}

Test::NoWarnings::had_no_warnings () if $r;

done_testing;
