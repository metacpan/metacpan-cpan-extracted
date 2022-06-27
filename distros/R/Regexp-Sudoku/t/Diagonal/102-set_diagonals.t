#!/usr/bin/perl

use 5.028;

use strict;
use warnings;
no  warnings 'syntax';

use experimental 'signatures';
use experimental 'lexical_subs';

use lib qw [lib ../lib];

use Test::More 0.88;

our $r = eval "require Test::NoWarnings; 1";

use Regexp::Sudoku;

my $sudoku = Regexp::Sudoku:: -> new -> init;

foreach my $method ((map {"set_diagonal_$_"} qw [double triple]),
                    (map {"set_$_"}          qw [cross argyle]),
                    (map {"set_cross_$_"}    1 .. 34)) {
    can_ok ($sudoku, $method);
}


Test::NoWarnings::had_no_warnings () if $r;

done_testing;
