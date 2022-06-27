#!/usr/bin/perl

use 5.028;

use strict;
use warnings;
no  warnings 'syntax';

use experimental 'signatures';
use experimental 'lexical_subs';

use lib qw [lib ../lib];

use Test::More 0.88;

our $r = eval "require Test::NoWarnings; 1";

use Regexp::Sudoku;


sub run_test ($type, $size = 9) {
    subtest "\u$type for a $size x $size Sudoku" => sub {
        my $method = "set_diagonal_$type";
        my $sudoku = Regexp::Sudoku:: -> new -> init (size => $size) -> $method;
        my @exp_cells;
        for (my $r = 1; $r <= $size; $r ++) {
            my $c = $type eq "main" ? $r : $size - $r + 1;
            push @exp_cells => "R${r}C${c}";
        }
        my $name   = $type eq "main" ? "DM" : "Dm";
        @exp_cells = sort @exp_cells;
        my %exp_cells = map {$_ => 1} @exp_cells;
        my @got_cells = sort $sudoku -> house2cells ($name);

        is_deeply \@got_cells, \@exp_cells, "Cells in house $name";

        for my $r (1 .. $size) {
            for my $c (1 .. $size) {
                my $cell = "R${r}C${c}";
                my %got_houses = map {$_ => 1} $sudoku -> cell2houses ($cell);
                ok !($exp_cells {$cell} xor $got_houses {$name}),
                     $exp_cells {$cell} ?  "Cell $cell is in house '$name'"
                                        :  "Cell $cell is not in house '$name'"
            }
        }
    }
}

run_test "main";
run_test "minor";
run_test "main",   6;
run_test "minor",  6;
run_test "main",  16;
run_test "minor", 16;


Test::NoWarnings::had_no_warnings () if $r;

done_testing;
