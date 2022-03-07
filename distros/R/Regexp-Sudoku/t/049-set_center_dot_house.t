#!/usr/bin/perl

use 5.028;

use strict;
use warnings;
no  warnings 'syntax';

use lib qw [lib ../lib];

use Test::More 0.88;

our $r = eval "require Test::NoWarnings; 1";

use Regexp::Sudoku;

my %box_sizes = (
     9 => [3, 3],
    15 => [3, 5],
);

foreach my $size (sort {$a <=> $b} keys %box_sizes) {
    my $sudoku = Regexp::Sudoku:: -> new -> init (size   => $size)
                                         -> set_center_dot_house;

    my ($bw, $bh) = @{$box_sizes {$size}};
    my @exp_cells;
    for (my $r = ($bh + 1) / 2; $r <= $size; $r += $bh) {
        for (my $c = ($bw + 1) / 2; $c <= $size; $c += $bw) {
            push @exp_cells => "R${r}C${c}";
        }
    }

    @exp_cells = sort @exp_cells;

    my %exp_cells = map {$_ => 1} @exp_cells;
    my @got_cells = sort $sudoku -> house2cells ("CD");

    subtest "Center dots for size $size" => sub {
        is_deeply \@got_cells, \@exp_cells, "Center dot cells";

        for my $r (1 .. $size) {
            for my $c (1 .. $size) {
                my $cell = "R${r}C${c}";
                my %got_houses = map {$_ => 1} $sudoku -> cell2houses ($cell);
                ok !($exp_cells {$cell} xor $got_houses {"CD"}),
                     $exp_cells {$cell} ?  "Cell $cell is a center dot"
                                        :  "Cell $cell is not a center dot";
            }
        }
    }
}

Test::NoWarnings::had_no_warnings () if $r;

done_testing;
