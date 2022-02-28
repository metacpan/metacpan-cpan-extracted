#!/usr/bin/perl

use 5.028;

use strict;
use warnings;
no  warnings 'syntax';

use lib qw [lib ../lib];

use Test::More 0.88;

our $r = eval "require Test::NoWarnings; 1";

use Regexp::Sudoku;
use Regexp::Sudoku::Constants qw [:Constraints];


my $size     = 9;
my $box_size = 3;
my $sudoku_n = Regexp::Sudoku:: -> new -> init (size        => $size,
                                                constraints => $ANTI_KNIGHT);
my $sudoku_k = Regexp::Sudoku:: -> new -> init (size        => $size,
                                                constraints => $ANTI_KING);
foreach my $r1 (1 .. $size) {
    foreach my $c1 (1 .. $size) {
        my $cell1 = "R${r1}C${c1}";
        my $box1  = "B" . (1 + int (($c1 - 1) / $box_size)) . ","
                        . (1 + int (($r1 - 1) / $box_size));
        foreach my $r2 (1 .. $r1) {
            foreach my $c2 (1 .. $size) {
                my $cell2 = "R${r2}C${c2}";
                last if $cell1 eq $cell2;
                my $box2  = "B" . (1 + int (($c2 - 1) / $box_size)) . ","
                                . (1 + int (($r2 - 1) / $box_size));

                my $got_n = $sudoku_n -> must_differ ($cell1, $cell2);
                my $got_k = $sudoku_k -> must_differ ($cell1, $cell2);
                my $exp_n = $r1 == $r2 || $c1 == $c2 || $box1 eq $box2 ||
                          abs ($r2 - $r1) == 1 && abs ($c1 - $c2) == 2 ||
                          abs ($r2 - $r1) == 2 && abs ($c1 - $c2) == 1 
                          ? 1 : 0;
                my $exp_k = $r1 == $r2 || $c1 == $c2 || $box1 eq $box2 ||
                          abs ($r2 - $r1) == 1 && abs ($c1 - $c2) == 1 
                          ? 1 : 0;
                is $got_n, $exp_n,
                   $exp_n ? "Cells $cell1 and $cell2 must differ (anti-knight)"
                          : "Cells $cell1 and $cell2 can be same (anti-knight)";
                is $got_k, $exp_k,
                   $exp_k ? "Cells $cell1 and $cell2 must differ (anti-king)"
                          : "Cells $cell1 and $cell2 can be same (anti-king)";
            }
        }
    }
}

Test::NoWarnings::had_no_warnings () if $r;

done_testing;
