#!/usr/bin/perl

use 5.028;

use strict;
use warnings;
no  warnings 'syntax';

use Test::More 0.88;

use lib qw [lib ../../lib];

my $r;

BEGIN {
    $r = eval "require Test::NoWarnings; 1";
    use_ok ('Regexp::Sudoku::Constants') or
        BAIL_OUT ("Loading of 'Regexp::Sudoku::Constants' failed");
}

ok defined $Regexp::Sudoku::Constants::VERSION, 
           "Regexp::Sudoku::Constants::VERSION is set";

Test::NoWarnings::had_no_warnings () if $r;

done_testing;
