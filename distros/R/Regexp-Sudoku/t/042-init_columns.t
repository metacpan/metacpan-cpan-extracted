#!/usr/bin/perl

use 5.028;

use strict;
use warnings;
no  warnings 'syntax';

use lib qw [lib ../lib];

use Test::More 0.88;

our $r = eval "require Test::NoWarnings; 1";

use Regexp::Sudoku;


foreach my $size (4, 6, 9, 12, 16) {
    my $sudoku = Regexp::Sudoku:: -> new;  # Don't call init(), as that
                                           # will create houses.
    subtest "Columns for a ${size} x ${size} Sudoku" => sub {
        $sudoku -> init_sizes ({size => $size});
        $sudoku -> init_columns;
        foreach my $c (1 .. $size) {
            my $col = "C$c";
            my @got_cells = sort $sudoku -> house2cells ($col);
            my @exp_cells = sort map {"R${_}$col"} 1 .. $size;
            is_deeply \@got_cells, \@exp_cells, "Cells for column $col";
        }
    };

    subtest "Cells for a ${size} x ${size} Sudoku" => sub {
        for my $c (1 .. $size) {
            my $col = "C$c";
            for my $r (1 .. $size) {
                my $cell = "R${r}C${c}";
                my @got_houses = sort $sudoku -> cell2houses ($cell);
                my @exp_houses = sort ($col);
                is_deeply \@got_houses, \@exp_houses, "Columns for cell $cell";
            }
        }
    }
}


Test::NoWarnings::had_no_warnings () if $r;

done_testing;
