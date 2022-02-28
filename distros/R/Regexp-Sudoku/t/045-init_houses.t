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

my $boxes = {
    4 => [2, 2],    # Sudoku size => [box width, box height]
    6 => [3, 2],
    9 => [3, 3],
   12 => [4, 3],
   15 => [5, 3],
   16 => [4, 4],
};

foreach my $size (sort {$a <=> $b} keys %$boxes) {
    subtest "size = $size" => sub {
        my $sudoku = Regexp::Sudoku:: -> new -> init (size => $size);

        my @exp_cells;
        my @exp_houses;
        my %exp_cell2houses;
        my %exp_house2cells;

        push @exp_houses => map {"R$_"} 1 .. $size;
        push @exp_houses => map {"C$_"} 1 .. $size;

        my ($bw, $bh) = @{$$boxes {$size}};

        for my $w (1 .. $bh) {
            for my $h (1 .. $bw) {
                push @exp_houses => "B${h}-${w}";
            }
        }

        for my $r (1 .. $size) {
            for my $c (1 .. $size) {
                my $cell   = "R${r}C${c}";
                my $row    = "R${r}";
                my $column = "C${c}";
                my $w      =  1 + int (($c - 1) / $bw);
                my $h      =  1 + int (($r - 1) / $bh);
                my $box    = "B${h}-${w}";

                push @exp_cells => $cell;
                $exp_cell2houses {$cell}   {$row}    = 1;
                $exp_cell2houses {$cell}   {$column} = 1;
                $exp_cell2houses {$cell}   {$box}    = 1;
                $exp_house2cells {$row}    {$cell}   = 1;
                $exp_house2cells {$column} {$cell}   = 1;
                $exp_house2cells {$box}    {$cell}   = 1;
            }
        }

           @exp_cells  = sort {$a cmp $b} @exp_cells;
        my @got_cells  = sort {$a cmp $b} $sudoku -> cells;
           @exp_houses = sort {$a cmp $b} @exp_houses;
        my @got_houses = sort {$a cmp $b} $sudoku -> houses;

        is_deeply \@got_cells,  \@exp_cells,  "cells";
        is_deeply \@got_houses, \@exp_houses, "houses";

        foreach my $cell (@exp_cells) {
            my @exp_houses = sort {$a cmp $b} keys %{$exp_cell2houses {$cell}};
            my @got_houses = sort {$a cmp $b} $sudoku ->  cell2houses ($cell);
            is_deeply \@got_houses, \@exp_houses, "Houses for cell $cell";
        }
        foreach my $house (@exp_houses) {
            my @exp_cells  = sort {$a cmp $b} keys %{$exp_house2cells {$house}};
            my @got_cells  = sort {$a cmp $b} $sudoku ->  house2cells ($house);
            is_deeply \@got_cells, \@exp_cells, "Cells for house $house";
        }
    };
}

throws_ok {
    Regexp::Sudoku:: -> new -> init (houses => 1 << 20)
} qr /^Unknown house\(s\)/, "Do not accept unknown houses";


Test::NoWarnings::had_no_warnings () if $r;

done_testing;
