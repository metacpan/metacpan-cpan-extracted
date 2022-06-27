#!/usr/bin/perl

use 5.028;

use strict;
use warnings;
no  warnings 'syntax';

use lib qw [lib ../lib];

use Test::More 0.88;

our $r = eval "require Test::NoWarnings; 1";

use Regexp::Sudoku;
use Regexp::Sudoku::Utils;

my $cell  = "R2C3";

my @tests = (
    ['', '2468', '13579',
         "[1-9]*(?<$cell>[1-9])[1-9]*",          "Defaults"],
    [4,  '24',   '13',
         "[1-4]*(?<$cell>[1-4])[1-4]*",          "Small size"],
    [12, '2468AC', '13579B',
         "[1-9A-C]*(?<$cell>[1-9A-C])[1-9A-C]*", "Larger size"],
);

foreach my $test (@tests) {
    my ($size, $exp_sub_e, $exp_sub_o, $exp_pat, $name) = @$test;
    $exp_sub_e .= $SENTINEL;
    $exp_sub_o .= $SENTINEL;
    $exp_pat   .= $SENTINEL;
    my %args = ();
       $args {size} = $size if $size;

    my $sudoku = Regexp::Sudoku:: -> new -> init (%args);

    my ($got_sub_e, $got_pat_e) = $sudoku -> make_even_statement ($cell);
    my ($got_sub_o, $got_pat_o) = $sudoku -> make_odd_statement  ($cell);

    subtest $name => sub {
        is $got_sub_e, $exp_sub_e, "Subject/evens";
        is $got_pat_e, $exp_pat,   "Pattern/evens";
        is $got_sub_o, $exp_sub_o, "Subject/odds";
        is $got_pat_o, $exp_pat,   "Pattern/odds";
    }
}

Test::NoWarnings::had_no_warnings () if $r;

done_testing;
