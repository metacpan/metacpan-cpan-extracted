#!/usr/bin/perl

use 5.028;

use strict;
use warnings;
no  warnings 'syntax';

use lib qw [lib ../lib];

use Test::More 0.88;
use Test::Exception;

our $r = eval "require Test::NoWarnings; 1";

use Regexp::Sudoku;
use Regexp::Sudoku::Constants qw [:Constraints];

my @tests = (
    $ANTI_KING                  =>  "Anti King constraint",
    $ANTI_KNIGHT                =>  "Anti Knight constraint",
    $ANTI_KING |. $ANTI_KNIGHT  =>  "Set two constraints",
);


my $sudoku = Regexp::Sudoku:: -> new;

while (@tests) {
    my ($constraint, $name) = splice @tests, 0, 2;

    subtest $name => sub {
        ok $sudoku -> init_constraints ({constraints => $constraint}),
               "Set constraint";
        is $sudoku -> constraints (), $constraint, "Retrieved constraint";
    };
}


throws_ok {
    $sudoku -> init_constraints ({constraints => 1 << 20});
} qr /^Unknown constraint\(s\)/, "Do not accept constrains which do not exist";
    

Test::NoWarnings::had_no_warnings () if $r;

done_testing;
