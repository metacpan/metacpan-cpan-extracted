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

    $sudoku -> init_sizes ({size => $size});
    $sudoku -> init_boxes;

    my $box_width    = $sudoku -> box_width;
    my $box_height   = $sudoku -> box_height;

    my $nr_hor_boxes = $size / $box_width;
    my $nr_ver_boxes = $size / $box_height;

    my %exp_cells;
    my %exp_boxes;
    for my $r (1 .. $size) {
        for my $c (1 .. $size) {
            my $br   = 1 + int (($r - 1) / $box_height);
            my $bc   = 1 + int (($c - 1) / $box_width);
            my $box  = "B${br}-${bc}";
            my $cell = "R${r}C${c}";
            push @{$exp_cells {$box}}  => $cell;
            push @{$exp_boxes {$cell}} => $box;
        }
    }
        
    subtest "Boxes for a ${size} x ${size} Sudoku" => sub {
        for my $r (1 .. $nr_ver_boxes) {
            for my $c (1 .. $nr_hor_boxes) {
                my $box = "B${r}-${c}";
                my @got_cells = sort $sudoku -> house2cells ($box);
                my @exp_cells = sort @{$exp_cells {$box}};
                is_deeply \@got_cells, \@exp_cells, "Cells for box $box";
            }
        }
    };

    subtest "Cells for a ${size} x ${size} Sudoku" => sub {
        for my $r (1 .. $size) {
            for my $c (1 .. $size) {
                my $cell = "R${r}C${c}";

                my @got_houses = sort $sudoku -> cell2houses ($cell);
                my @exp_houses = sort @{$exp_boxes {$cell}};
                is_deeply \@got_houses, \@exp_houses, "Boxes for cell $cell";
            }
        }
    }
}


Test::NoWarnings::had_no_warnings () if $r;

done_testing;
