#!/usr/bin/perl

use 5.028;

use strict;
use warnings;
no  warnings 'syntax';

use lib qw [lib ../lib t .];

use Test::More 0.88;

our $r = eval "require Test::NoWarnings; 1";

use Test;

run_sudoku "sudokus/renban-1";
run_sudoku "sudokus/renban-2";
SKIP: {
    skip "Takes too long", 1 unless $ENV {PERL_TEST_LONG} || $ENV {TEST_LONG};
    run_sudoku "sudokus/renban-3";
}

Test::NoWarnings::had_no_warnings () if $r;

done_testing;
