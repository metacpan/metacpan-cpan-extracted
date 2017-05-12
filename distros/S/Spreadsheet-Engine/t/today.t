#!/usr/bin/perl

use strict;
use warnings;
use lib ('lib', 't/lib');

use SheetTest;
use Test::More;

my $tries = 0;
TRYAGAIN:    # Try to get only the seconds to differ
my @t1    = localtime;
my $sheet = run_tests();
my @t2    = localtime;
if ($t2[1] != $t1[1]) {
  goto TRYAGAIN unless ++$tries > 20;
  plan skip_all => 'Insufficient precision on NOW()';
}
plan tests => 9;

my $raw = $sheet->raw;
is $raw->{datavalues}{A1}, $t1[5] + 1900, 'TODAY() year';
is $raw->{datavalues}{A2}, $t1[4] + 1,    'TODAY() month';
is $raw->{datavalues}{A3}, $t1[3], 'TODAY() day';

is $raw->{datavalues}{B1}, 1, 'TODAY() year == NOW() year';
is $raw->{datavalues}{B2}, 1, 'TODAY() month == NOW() month';
is $raw->{datavalues}{B3}, 1, 'TODAY() day == NOW() day';

is $raw->{datavalues}{C1}, $t1[2], 'NOW() year';
is $raw->{datavalues}{C2}, $t1[1], 'NOW() month';
my $matched = grep $raw->{datavalues}{C3} == $_, $t1[0] .. $t2[0];
ok $matched, 'NOW() second'
  or diag "Couldn'd find $raw->{datavalues}{C3} between $t1[0] and $t2[0]";

__DATA__
set A1 formula YEAR(TODAY())
set A2 formula MONTH(TODAY())
set A3 formula DAY(TODAY())

set B1 formula IF(YEAR(NOW())=YEAR(TODAY()),1,0)
set B2 formula IF(MONTH(NOW())=MONTH(TODAY()),1,0)
set B3 formula IF(DAY(NOW())=DAY(TODAY()),1,0)

set C1 formula HOUR(NOW())
set C2 formula MINUTE(NOW())
set C3 formula SECOND(NOW())

