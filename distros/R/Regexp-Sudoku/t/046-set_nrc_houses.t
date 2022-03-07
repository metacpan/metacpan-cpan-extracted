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

my $sudoku = Regexp::Sudoku:: -> new
                              -> init
                              -> set_nrc_houses;

my @tl = (undef, [2, 2], [2, 6], [6, 2], [6, 6]);
my @EXP_CELLS;

foreach my $i (1 .. 4) {
    my $tl = $tl [$i];
    foreach my $dr (0 .. 2) {
        foreach my $dc (0 .. 2) {
            push @{$EXP_CELLS [$i]} =>
                sprintf "R%dC%d" => $$tl [0] + $dr, $$tl [1] + $dc;
        }
    }
}

foreach my $i (1 .. 4) {
    my $name      = "NRC$i";
    my @exp_cells = @{$EXP_CELLS [$i]};
    my %exp_cells = map {$_ => 1} @exp_cells;

    my @got_cells = sort $sudoku -> house2cells ($name);

    subtest "House $name", sub {
        is_deeply \@got_cells, \@exp_cells, "Cells in $name";

        for my $r (1 .. $size) {
            for my $c (1 .. $size) {
                my $cell = "R${r}C${c}";
                my %got_houses = map {$_ => 1} $sudoku -> cell2houses ($cell);
                ok !($exp_cells {$cell} xor $got_houses {$name}),
                     $exp_cells {$cell} ?  "Cell $cell in $name"
                                        :  "Cell $cell not in $name";
            }
        }
    }
}

Test::NoWarnings::had_no_warnings () if $r;

done_testing;
