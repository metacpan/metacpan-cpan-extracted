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

sub run_test ($name, @renbans) {
    subtest $name => sub {
        my %exp;
        my $sudoku = Regexp::Sudoku:: -> new -> init;
        foreach my $renban (@renbans) {
            $sudoku -> set_renban (@$renban)
        }
        foreach my $i (keys @renbans) {
            my $name = "REN-" . ($i + 1);
            my $set  = $renbans [$i];
            foreach my $cell (@$set) {
                $exp {$cell} {$name} = 1;
            }
            my @got = $sudoku -> renban2cells ($name);
            is_deeply [sort @got], [sort @$set], "renban2cells ($name)";
        }
        foreach my $cell (keys %exp) {
            my @got = $sudoku -> cell2renbans ($cell);
            is_deeply [sort @got], [sort keys %{$exp {$cell}}],
                                                 "cell2renbans ($cell)";
        }
    }
}

run_test "Single, small set", [qw [R1C1 R1C2]];
run_test "Single, large set", [qw [R1C1 R1C2 R1C3
                                   R2C2 R3C3 R4C3
                                   R5C3 R5C2 R5C1]];
run_test "Multiple non-overlapping sets", 
                              [qw [R1C1 R1C2]], [qw [R2C2 R2C3]], 
                              [qw [R3C3 R3C4]], [qw [R4C4 R4C5]];
run_test "Two overlapping sets", 
                              [qw [R2C1 R2C2 R2C3]], 
                              [qw [R1C2 R2C2 R3C2]]; 
run_test "Multiple overlapping sets", 
                              [qw [R1C1 R1C2 R1C3 R1C4 R1C5 R1C6]],
                              [qw [R2C1 R2C2 R2C3 R2C4 R2C5 R2C6]],
                              [qw [R3C1 R3C2 R3C3 R3C4 R3C5 R3C6]],
                              [qw [R4C1 R4C2 R4C3 R4C4 R4C5 R4C6]],
                              [qw [R5C1 R5C2 R5C3 R5C4 R5C5 R5C6]],
                              [qw [R6C1 R6C2 R6C3 R6C4 R6C5 R6C6]],
                              [qw [R1C1 R2C1 R3C1 R4C1 R5C1 R6C1]],
                              [qw [R1C2 R2C2 R3C2 R4C2 R5C2 R6C2]],
                              [qw [R1C3 R2C3 R3C3 R4C3 R5C3 R6C3]],
                              [qw [R1C4 R2C4 R3C4 R4C4 R5C4 R6C4]],
                              [qw [R1C5 R2C5 R3C5 R4C5 R5C5 R6C5]],
                              [qw [R1C6 R2C6 R3C6 R4C6 R5C6 R6C6]];

Test::NoWarnings::had_no_warnings () if $r;

done_testing;
