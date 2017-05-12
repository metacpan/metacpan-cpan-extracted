#!/usr/bin/perl

# Test cases from Open Formula Specification 1.2 pp121ff
# OpenFormula-v1.2-draft7.odtOpenFormula-v1.2-draft7.odt
# Copyright (C) OASIS Open 2006. All Rights Reserved

use strict;
use warnings;
use lib ('lib', 't/lib');

use SheetTest;
use Test::More tests => 13;

run_tests(against => 't/data/openformula-testsuite.txt');

__DATA__

set A101 formula DAVERAGE(TESTDB,"TestID",B36:B37) 
test A101 48

set A102 formula DCOUNT(TESTDB,"Bright Stars",B36:B37)
test A102 2

set A103 formula DCOUNTA(TESTDB,"Bright Stars",B36:B37) 
test A103 2

set A104 formula DGET(TESTDB,"TestID",D36:D37) 
test A104 2048

set A105 formula DGET(TESTDB,"TestID",B36:B37)
iserror A105

set A106 formula DMAX(TESTDB,"TestID",B36:B37) 
test A106 64

set A107 formula DMIN(TESTDB,"TestID",B36:B37) 
test A107 32

set A108 formula DPRODUCT(TESTDB,"TestID",B36:B37) 
test A108 2048

set A109 formula DSTDEV(TESTDB,"TestID",B36:B37) 
like A109 ^22.6274169979695

set A110 formula DSTDEVP(TESTDB,"TestID",B36:B37) 
test A110 16

set A111 formula DSUM(TESTDB,"TestID",B36:B37) 
test A111 96

set A112 formula DVAR(TESTDB,"TestID",B36:B37) 
test A112 512

set A113 formula DVARP(TESTDB,"TestID",B36:B37) 
test A113 256

