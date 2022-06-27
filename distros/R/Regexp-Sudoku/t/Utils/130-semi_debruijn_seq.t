#!/usr/bin/perl

use 5.028;

use strict;
use warnings;
no  warnings 'syntax';

use lib qw [lib ../lib ../../lib];

use Test::More 0.88;

our $r = eval "require Test::NoWarnings; 1";

use Regexp::Sudoku::Utils;

my @vals = (1 .. 9, 'A' .. 'Z');

for my $size (4, 9, 16) {
    my @values = @vals [0 .. $size - 1];
    my $values = join "" => @values;
    my $seq    = semi_debruijn_seq ($values);

    subtest "Size: $size", sub {
        subtest "Pairs in sequence" => sub {
            foreach my $ch1 (@values) {
                foreach my $ch2 (@values) {
                    my $pair = "$ch1$ch2";
                    if ($ch1 eq $ch2) {
                        ok index ($seq, $pair) <  0, "'$pair' not in sequence"
                    }
                    else {
                        ok index ($seq, $pair) >= 0, "'$pair' in sequence"
                    }
                }
            }
        }
    }
}

Test::NoWarnings::had_no_warnings () if $r;

done_testing;
