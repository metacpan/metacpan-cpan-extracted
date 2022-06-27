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

use Regexp::Sudoku::Utils;

sub run_tests ($name, $set1, $set2) {
    my $subject = all_pairs ($set1, $set2);
    subtest $name => sub {
        foreach my $ch1 (split // => $set1) {
            foreach my $ch2 (split // => $set2) {
                ok $subject =~ /$ch1$ch2/, "Match for '$ch1$ch2'";
                ok $subject =~ /$ch2$ch1/, "Match for '$ch2$ch1'";
            }
        }
        foreach my $ch1 (split // => $set1) {
            foreach my $ch2 (split // => $set1) {
                ok $subject !~ /$ch1$ch2/, "No match for '$ch1$ch2'"
            }
        }
        foreach my $ch1 (split // => $set2) {
            foreach my $ch2 (split // => $set2) {
                ok $subject !~ /$ch1$ch2/, "No match for '$ch1$ch2'"
            }
        }
    };
}
        
run_tests "Odds and evens",      "2468",  "13579";
run_tests "Same sized sets",     "02468", "13579";
run_tests "Small and large set", "12",    "3456789";

Test::NoWarnings::had_no_warnings () if $r;

done_testing;
