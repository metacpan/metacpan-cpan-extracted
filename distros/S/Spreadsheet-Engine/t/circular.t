#!/usr/bin/perl

use strict;
use warnings;
use lib ('lib', 't/lib');

use SheetTest;
use Test::More tests => 1;

my $sheet = run_tests();

is $sheet->raw->{sheetattribs}->{circularreferencecell}, 'A4|A4', 'Circular';

__DATA__
set A1 value n 2
set A2 value n 3
set A3 value n 4
set A4 formula SUM(A1:A4)

