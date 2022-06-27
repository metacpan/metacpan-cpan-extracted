#!/usr/bin/perl

use 5.028;

use strict;
use warnings;
no  warnings 'syntax';

use experimental 'signatures';
use experimental 'lexical_subs';

use lib qw [lib ../lib ../../lib];

use Test::More 0.88;

our $r = eval "require Test::NoWarnings; 1";

use Regexp::Sudoku;

sub run_test ($name, %quadruples) {
    subtest $name => sub {
        my %exp;
        my $sudoku = Regexp::Sudoku:: -> new -> init;
        $sudoku -> set_quadruples (%quadruples);

        foreach my $cell (keys %quadruples) {
            my $name = "Q-$cell";
            my ($r, $c) = $cell =~ /R([0-9]+)C([0-9]+)/;
            my @exp_set = (sprintf ("R%dC%d", $r,     $c),
                           sprintf ("R%dC%d", $r,     $c + 1),
                           sprintf ("R%dC%d", $r + 1, $c),
                           sprintf ("R%dC%d", $r + 1, $c + 1));
            $exp {$_} {$name} = 1 for @exp_set;

            my @got = $sudoku -> quadruple2cells ($name);
            is_deeply [sort @got], [sort @exp_set], "quadruple2cells ($name)";

            my @got2 = $sudoku -> quadruple_values ($name);
            my @exp2 = @{$quadruples {$cell}};
            is_deeply [sort @got2], [sort @exp2], "quadruple_values ($name)";
        }
        foreach my $cell (keys %exp) {
            my @got = $sudoku -> cell2quadruples ($cell);
            is_deeply [sort @got], [sort keys %{$exp {$cell}}],
                                                 "cell2quadruples ($cell)";
        }
    }
}

run_test "Single quadruple, single value",    R1C1 => [1];
run_test "Single quadruple, more values",     R1C1 => [1, 2, 3];
run_test "Single quadruple, repeated values", R1C1 => [1, 2, 2, 3];
run_test "Two non-overlapping quadruples",    R2C2 => [1, 6],
                                              R7C4 => [3, 4, 5];
run_test "Two overlapping quadruples",        R3C3 => [5, 5, 6],
                                              R4C3 => [6, 7];
run_test "Many quadruples",                   R3C3 => [5, 5, 6],
                                              R4C3 => [6, 7],
                                              R2C2 => [1, 6],
                                              R7C4 => [3, 4, 5],
                                              R1C1 => [1, 2, 2, 3];

Test::NoWarnings::had_no_warnings () if $r;

done_testing;

__END__
