#!/usr/bin/perl

use strict;
use warnings;
use lib ('lib', 't/lib');

use SheetTest;

use Test::More tests => 2 * 12;

my $sheet = run_tests();
for my $cell (map "A$_", 1 .. 12) {
  is $sheet->raw->{valuetypes}->{$cell}, 'e#VALUE!', "$cell = Error";
  like $sheet->raw->{datavalues}->{$cell}, qr/arguments/,
    "$cell incorrect args";
}

__DATA__

# series
set A1 formula SUM()

# math
set A2 formula SIN(90,3)

# math2
set A3 formula POWER()
set A4 formula POWER(10)
set A5 formula POWER(10,2,2)

# count
set A6 formula COUNT()

# IS
set A7 formula ISTEXT()
set A8 formula ISTEXT(6, "a")

# Zero args
set A9 formula PI(3)

# Too many
set A10 formula ROUND(87,3,3)
set A11 formula WEEKDAY("2007-01-01",2,"y")

# PMT
set A12 formula PMT(10,0,10)
