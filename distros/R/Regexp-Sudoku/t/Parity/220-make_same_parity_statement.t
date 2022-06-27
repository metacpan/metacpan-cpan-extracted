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
use Regexp::Sudoku::Utils;

my $sudoku = Regexp::Sudoku:: -> new -> init;

my $cell1 = "R1C1";
my $cell2 = "R2C2";

my ($sub0, $pat0) = $sudoku -> make_same_parity_statement ($cell1, $cell2, 0);
my ($sub1, $pat1) = $sudoku -> make_same_parity_statement ($cell1, $cell2, 1);

foreach my $val1 (1 .. 9) {
    foreach my $val2 (1 .. 9) {
        my $exp0 = ($val1 % 2) == ($val2 % 2);
        my $exp1 = ($val1 % 2) == ($val2 % 2) && $val1 != $val2;
        my $s0   = "$val1$SENTINEL$val2$SENTINEL$sub0";
        my $s1   = "$val1$SENTINEL$val2$SENTINEL$sub1";
        my $p0   = "(?<$cell1>$val1)$SENTINEL(?<$cell2>$val2)$SENTINEL$pat0";
        my $p1   = "(?<$cell1>$val1)$SENTINEL(?<$cell2>$val2)$SENTINEL$pat1";
        ok !($exp0 xor $s0 =~ /^$p0$/), 
             $exp0 ? "Match same parity of '$val1' and '$val2'"
                   : "Do not match different parity of '$val1' and '$val2'";
        ok !($exp1 xor $s1 =~ /^$p1$/), 
             $exp1 ? "Match same parity of '$val1' and '$val2' (values differ)"
  : $val1 == $val2 ? "Do not match equal values '$val1' and '$val2'"
                   : "Do not match different parity of '$val1' and '$val2'";
    }
}

Test::NoWarnings::had_no_warnings () if $r;

done_testing;
