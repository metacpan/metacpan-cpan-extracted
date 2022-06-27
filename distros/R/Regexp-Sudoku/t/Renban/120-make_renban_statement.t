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

for (my $size = 2; $size <= 9; $size ++) {
    subtest "Renban size $size" => sub {
        my @cells  = map {"R${_}C${_}"} 1 .. $size;
        my $sudoku = Regexp::Sudoku:: -> new
                                      -> init 
                                      -> set_renban (@cells);
        my $cell1  = "R1C1";
        my $cell2  = "R${size}C${size}";
        my ($subject, $pattern) = $sudoku -> make_renban_statement
                                                ($cell1, $cell2);
        SKIP: {
            ok $subject, "Got subject $subject";
            ok $pattern, "Got pattern";
            skip "Did not get subject and pattern", 81
                      unless $subject &&  $pattern;

            foreach my $i (1 .. 9) {
                foreach my $j (1 .. 9) {
                    my $pat = "(?:[1-9][1-9])*$i$j(?:[1-9][1-9])*$SENTINEL";
                    if ($i == $j) {
                        ok $subject !~ /^$pat$/, "$i does not duplicate";
                    }
                    elsif (abs ($i - $j) >= $size) {
                        ok $subject !~ /^$pat$/,
                         "$i and $j cannot appear together in this renban";
                    }
                    else {
                        ok $subject =~ /^$pat$/,
                         "$i and $j can appear together in this renban";
                    }
                }
            }
        }
    }
}



Test::NoWarnings::had_no_warnings () if $r;

done_testing;
