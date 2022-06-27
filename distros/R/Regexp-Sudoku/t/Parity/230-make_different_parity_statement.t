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
my $cell2 = "R1C2";

my ($sub, $pat) = $sudoku -> make_different_parity_statement ($cell1, $cell2);

foreach my $val1 (1 .. 9) {
    foreach my $val2 (1 .. 9) {
        my $exp = ($val1 % 2) != ($val2 % 2);
        my $s   = "$val1$SENTINEL$val2$SENTINEL$sub";
        my $p   = "(?<$cell1>$val1)$SENTINEL(?<$cell2>$val2)$SENTINEL$pat";
        ok !($exp xor $s =~ /^$p$/), 
             $exp ? "Match different parity of '$val1' and '$val2'"
                  : "Do not match same parity of '$val1' and '$val2'";
    }
}

Test::NoWarnings::had_no_warnings () if $r;

done_testing;
