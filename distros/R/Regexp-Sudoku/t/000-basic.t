#!/usr/bin/perl

use 5.028;

use strict;
use warnings;
no  warnings 'syntax';

use lib qw [lib ../lib];

use Test::More 0.88;
use Test::Exception;

our $r = eval "require Test::NoWarnings; 1";

BEGIN {
    use_ok ('Regexp::Sudoku') or
        BAIL_OUT ("Loading of 'Regexp::Sudoku' failed");
}

ok defined $Regexp::Sudoku::VERSION, "VERSION is set";

my $sudoku = Regexp::Sudoku:: -> new;

isa_ok $sudoku, 'Regexp::Sudoku';

Test::NoWarnings::had_no_warnings () if $r;

done_testing;
