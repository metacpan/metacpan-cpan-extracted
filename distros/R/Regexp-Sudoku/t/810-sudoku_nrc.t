#!/usr/bin/perl

use 5.028;

use strict;
use warnings;
no  warnings 'syntax';

use lib qw [lib ../lib t .];

use Test::More 0.88;

our $r = eval "require Test::NoWarnings; 1";

use Test;

run_sudoku "sudokus/nrc";
run_sudoku "sudokus/nrc-2018-12-31";


Test::NoWarnings::had_no_warnings () if $r;

done_testing;
