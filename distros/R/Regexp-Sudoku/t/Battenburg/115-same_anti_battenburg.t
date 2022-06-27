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

my $sudoku = Regexp::Sudoku:: -> new -> init
             -> set_anti_battenburg (qw [R2C2 R5C3 R6C3]);

my @cells = map {my $r = $_; map {"R${r}C${_}"} 1 .. 9} 1 .. 9;

for (my $i = 0; $i < @cells; $i ++) {
    my $cell1 = $cells [$i];
    my ($r1, $c1) = $cell1 =~ /R([1-9]+)C([1-9]+)/;
    for (my $j = $i + 1; $j < @cells; $j ++) {
        my $cell2 = $cells [$j];
        my ($r2, $c2) = $cell2 =~ /R([1-9]+)C([1-9]+)/;
        my @exp;
        push @exp => "R2C2" if ($r1 == 2 || $r1 == 3) &&
                               ($r2 == 2 || $r2 == 3) &&
                               ($c1 == 2 || $c1 == 3) &&
                               ($c2 == 2 || $c2 == 3);

        push @exp => "R5C3" if ($r1 == 5 || $r1 == 6) &&
                               ($r2 == 5 || $r2 == 6) &&
                               ($c1 == 3 || $c1 == 4) &&
                               ($c2 == 3 || $c2 == 4);

        push @exp => "R6C3" if ($r1 == 6 || $r1 == 7) &&
                               ($r2 == 6 || $r2 == 7) &&
                               ($c1 == 3 || $c1 == 4) &&
                               ($c2 == 3 || $c2 == 4);


        my @got = $sudoku -> same_anti_battenburg ($cell1, $cell2);
        my $got = $sudoku -> same_anti_battenburg ($cell1, $cell2);
           @exp = sort @exp;
           @got = sort @got;
        my $exp = @exp;

        subtest "same_anti_battenburg ($cell1, $cell2)" => sub {
            is_deeply \@got, \@exp,   "(LIST context)";
            is_deeply  $got,  $exp, "(SCALAR context)";
        }
    }
}



Test::NoWarnings::had_no_warnings () if $r;

done_testing;
