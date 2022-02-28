#!/usr/bin/perl

use 5.028;

use strict;
use warnings;
no  warnings 'syntax';

use lib qw [lib ../lib];

use Test::More 0.88;

our $r = eval "require Test::NoWarnings; 1";

use Regexp::Sudoku;

foreach my $r (1 .. 9) {
    foreach my $c (1 .. 9) {
        my $got = Regexp::Sudoku::cell_name ($r, $c);
        my $exp = "R${r}C${c}";
        is $got, $exp, "[$r, $c] -> $exp";

        my ($got_r, $got_c) = Regexp::Sudoku::cell_row_column ($exp);
        ok $got_r == $r && $got_c == $c, "$exp -> [$r, $c]";
    }
}


Test::NoWarnings::had_no_warnings () if $r;

done_testing;
