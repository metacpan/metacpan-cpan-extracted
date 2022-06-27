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
my $sudoku  = Regexp::Sudoku:: -> new -> init;

my $cell1   = "R3C4";
my $cell2   = "R3C5";

my $exp_sub = "1617181927282938394961717281828391929394;";
my $exp_pat = "(?:[1-9][1-9])*\\g{$cell1}\\g{$cell2}(?:[1-9][1-9])*;";

my ($got_sub, $got_pat) = $sudoku ->
                           make_german_whisper_statement ($cell1, $cell2);


Test::NoWarnings::had_no_warnings () if $r;

done_testing;
