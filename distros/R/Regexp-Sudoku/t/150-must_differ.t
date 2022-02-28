#!/usr/bin/perl

use 5.028;

use strict;
use warnings;
no  warnings 'syntax';

use lib qw [lib ../lib];

use Test::More 0.88;

our $r = eval "require Test::NoWarnings; 1";

use Regexp::Sudoku;

my $box = {
    4  =>  [2, 2],
    6  =>  [3, 2],
    9  =>  [3, 3],
   12  =>  [4, 3],
   16  =>  [4, 4],
};


for my $size (sort {$a <=> $b} keys %$box) {
    my $sudoku  = Regexp::Sudoku:: -> new -> init (size => $size);
    my ($bw, $bh) = @{$$box {$size}};
    subtest "Size = $size", sub {
        foreach my $r1 (1 .. $size) {
            foreach my $c1 (1 .. $size) {
                my $cell1 = "R${r1}C${c1}";
                my $box1  = "B" . (1 + int (($c1 - 1) / $bw)) . ","
                                . (1 + int (($r1 - 1) / $bh));
                foreach my $r2 (1 .. $r1) {
                    foreach my $c2 (1 .. $size) {
                        my $cell2 = "R${r2}C${c2}";
                        last if $cell1 eq $cell2;
                        my $box2  = "B" . (1 + int (($c2 - 1) / $bw)) . ","
                                        . (1 + int (($r2 - 1) / $bh));

                        my $got = $sudoku -> must_differ ($cell1, $cell2);
                        my $exp = $r1 == $r2 || $c1 == $c2 ||
                                  $box1 eq $box2 ? 1 : 0;
                        is $got, $exp,
                                 $exp ? "Cells $cell1 and $cell2 must differ"
                                      : "Cells $cell1 and $cell2 can be same";
                    }
                }
            }
        }
    };
}

Test::NoWarnings::had_no_warnings () if $r;

done_testing;
