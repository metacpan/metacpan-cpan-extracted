#!/usr/bin/perl

use 5.028;

use strict;
use warnings;
no  warnings 'syntax';

use lib qw [lib ../lib];

use Test::More 0.88;

our $r = eval "require Test::NoWarnings; 1";

use Regexp::Sudoku;

my $sudoku = Regexp::Sudoku:: -> new;  # Don't call init(), as that
                                       # will create houses.

my $name1  = "H1";
my $name2  = "V1";
my @cells1 = map {"H1V${_}"} 1 .. 9;
my @cells2 = map {"H${_}V1"} 1 .. 9;

$sudoku -> create_house ($name1 => @cells1);

my @got_cells = sort $sudoku -> house2cells ($name1);
my @exp_cells = sort @cells1;
is_deeply \@got_cells, \@exp_cells, "Cells for house $name1";

foreach my $cell (@cells1) {
    my @got_houses = sort $sudoku -> cell2houses ($cell);
    my @exp_houses = sort ($name1);
    is_deeply \@got_houses, \@exp_houses, "House(s) for cell $cell";
}

$sudoku -> create_house ($name2 => @cells2);

@got_cells = sort $sudoku -> house2cells ($name2);
@exp_cells = sort @cells2;
is_deeply \@got_cells, \@exp_cells, "Cells for house $name2";

foreach my $cell (@cells2) {
    my @got_houses = sort $sudoku -> cell2houses ($cell);
    my @exp_houses = $cell eq "H1V1" ? sort ($name1, $name2) : sort ($name2);
    is_deeply \@got_houses, \@exp_houses, "House(s) for cell $cell";
}

Test::NoWarnings::had_no_warnings () if $r;

done_testing;
