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
    subtest "Rows for a ${size} x ${size} Sudoku" => sub {
        $sudoku -> init_sizes ({size => $size});
        $sudoku -> init_rows;
        foreach my $r (1 .. $size) {
            my $row = "R$r";
            my @got_cells = sort $sudoku -> house2cells ($row);
            my @exp_cells = sort map {"${row}C$_"} 1 .. $size;
            is_deeply \@got_cells, \@exp_cells, "Cells for row $row";
        }
    };

    subtest "Cells for a ${size} x ${size} Sudoku" => sub {
        for my $r (1 .. $size) {
            my $row = "R$r";
            for my $c (1 .. $size) {
                my $cell = "R${r}C${c}";
                my @got_houses = sort $sudoku -> cell2houses ($cell);
                my @exp_houses = sort ($row);
                is_deeply \@got_houses, \@exp_houses, "Rows for cell $cell";
            }
        }
    }
}


Test::NoWarnings::had_no_warnings () if $r;

done_testing;
