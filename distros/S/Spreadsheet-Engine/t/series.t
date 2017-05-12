#!/usr/bin/perl

use strict;
use warnings;
use lib ('lib', 't/lib');

use SheetTest;
use Test::More 'no_plan';

run_tests();

__DATA__
set A1 value n 10
set A2 value n 20
set A3 value n 30
set A4 constant nd 39367 2007-10-12
set A5 value n 100000
set A6 value t fred
set A7 empty

set B1 formula SUM(10)
test B1 10
testtype B1 n
set B2 formula SUM(10,20)
test B2 30
set B3 formula SUM(A1,10)
test B3 20
set B4 formula SUM(A1,A3)
test B4 40
set B5 formula SUM(A1:A3)
test B5 60
set B6 formula SUM(A1:A3,40)
test B6 100
set B7 formula SUM("fred","barney")
test B7 0
set B8 formula SUM()
like B8 Incorrect arguments
testtype B8 e#VALUE!

# Date + integer = Date
set C1 formula SUM(A4,A1)
# TODO test these as a display value
test C1 39377
testtype C1 nd
set C2 formula SUM(A1:A4)
test C2 39427
testtype C2 nd

set D1 formula MAX(A1:A3)
test D1 30
# currently sets result to date
# testtype D1 n
set D2 formula MAX(-100,0, 31.3)
test D2 31.3
set D3 formula MAX(A3:A4)
test D3 39367
testtype D3 nd
set D4 formula MAX(A4:A5)
test D4 100000

set E1 formula MIN(A1:A3)
test E1 10
set E2 formula MIN(-100,0, 31.3)
test E2 -100
set E3 formula MIN(A3:A4)
test E3 30
# currently sets result to date
# testtype E3 n
set E4 formula MIN(A4:A5)
test E4 39367
testtype E4 nd

set F1 formula AVERAGE(A1:A3)
test F1 20
set F2 formula AVERAGE(A4)
test F2 39367
testtype F2 nd
set F3 formula AVERAGE()
like F3 Incorrect arguments
testtype F3 e#VALUE!
set F4 formula AVERAGE(A2,A6)
test F4 20
set F5 formula AVERAGE(A6)
test F5 0
testtype F5 e#DIV/0!

set G1 formula COUNT(A1:A3)
test G1 3
set G2 formula COUNT(A1:A7)
test G2 5
set G3 formula COUNTA(A1:A7)
test G3 6
set G4 formula COUNTBLANK(A1:A7)
test G4 1

set H1 formula PRODUCT(A1:A3)
test H1 6000
set H2 formula PRODUCT(A5:A6)
test H2 100000

set I1 formula VAR(A1:A3)
test I1 100
set I2 formula VAR(90)
test I2 0
testtype I2 e#DIV/0!

set J1 formula STDEV(A1:A3)
test J1 10
set J2 formula STDEV(90)
test J2 0
testtype J2 e#DIV/0!

set K1 formula VARP(A2:A3)
test K1 25
set K2 formula STDEVP(A2:A3)
test K2 5

