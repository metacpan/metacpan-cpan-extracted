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
my $SENTINEL = "\n";

my $sudoku = Regexp::Sudoku:: -> new -> init;

my ($subject, $pattern) = $sudoku -> make_anti_battenburg_statement ("R3C7");

foreach my $r3c7 (1 .. 9) {
    foreach my $r3c8 (1 .. 9) {
        foreach my $r4c8 (1 .. 9) {
            foreach my $r4c7 (1 .. 9) {
                my $exp   = (($r3c7 % 2) == ($r3c8 % 2)) ||
                            (($r3c8 % 2) == ($r4c8 % 2)) ||
                            (($r4c8 % 2) == ($r4c7 % 2)) ||
                            (($r4c7 % 2) == ($r3c7 % 2));
                my $sub =          "$r3c7$SENTINEL" .
                                   "$r3c8$SENTINEL" .
                                   "$r4c8$SENTINEL" .
                                   "$r4c7$SENTINEL" . $subject;
                my $pat = "(?<R3C7>$r3c7)$SENTINEL" .
                          "(?<R3C8>$r3c8)$SENTINEL" .
                          "(?<R4C8>$r4c8)$SENTINEL" .
                          "(?<R4C7>$r4c7)$SENTINEL" . $pattern;
                my $got = $sub =~ /^$pat$/;
                ok !!$exp == !!$got, "$r3c7 $r3c8 $r4c8 $r4c7 " .
                                     ($exp ? "matches" : "does not match")
            }
        }
    }
}


Test::NoWarnings::had_no_warnings () if $r;

done_testing;
