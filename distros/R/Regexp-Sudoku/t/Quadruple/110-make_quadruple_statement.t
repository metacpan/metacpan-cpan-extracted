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



sub run_tests ($name, @values) {
    my $quadruple = "Q-R2C3";
    my $cell      = "R2C3";
    my @cells     = qw [R2C3 R2C4 R3C3 R3C4];
    my $exp_pat   = "\\g{R2C3}?\\g{R2C4}?\\g{R3C3}?\\g{R3C4}?$SENTINEL";

    my $sudoku = Regexp::Sudoku:: -> new -> init;
       $sudoku -> set_quadruples ($cell => \@values);

    my ($got_subs, $got_pats) =
        $sudoku -> make_quadruple_statements ($quadruple);

    my %values;
       $values {$_} .= $_ for @values;

    subtest $name => sub {
        is_deeply [sort @$got_subs],
                  [map {"$_$SENTINEL"} sort values %values],      "Subjects";
        is_deeply  $got_pats, [($exp_pat) x scalar keys %values], "Patterns";
    };

}

run_tests "Quadruple with one value",                     3;
run_tests "Quadruple with two values",                    3, 4;
run_tests "Quadruple with three values",                  3, 4, 5;
run_tests "Quadruple with four values",                   3, 4, 5, 6;
run_tests "Quadruple with two repeated values",           3, 3;
run_tests "Quadruple with three values, with a repeat",   3, 5, 5;
run_tests "Quadruple with four values, with one repeat",  3, 5, 5, 7;
run_tests "Quadruple with four values, with two repeats", 5, 5, 7, 7;

Test::NoWarnings::had_no_warnings () if $r;

done_testing;
