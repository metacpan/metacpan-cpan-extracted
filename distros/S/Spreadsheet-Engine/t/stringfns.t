#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 6;

use lib 'lib';
use Spreadsheet::Engine::Storage::SocialCalc;

my $sheet =
  Spreadsheet::Engine::Storage::SocialCalc->load('t/data/stringfns.txt');
$sheet->recalc;

my $raw = $sheet->raw;
for my $cell ('D2' .. 'D7') {
  ok $raw->{datavalues}{$cell}, "$cell is TRUE";
}
