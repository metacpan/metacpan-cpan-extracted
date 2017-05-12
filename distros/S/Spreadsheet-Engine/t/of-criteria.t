#!/usr/bin/perl

# Test cases from Open Formula Specification 1.2 pp56f
# OpenFormula-v1.2-draft7.odtOpenFormula-v1.2-draft7.odt
# Copyright (C) OASIS Open 2006. All Rights Reserved

use strict;
use warnings;
use lib ('lib', 't/lib');

use SheetTest;
use Test::More tests => 13;

run_tests(against => 't/data/openformula-testsuite.txt');

__DATA__

# Trivial criteria, checking for equal to a number. We use SUM on
# the TestID to make sure that EXACTLY the right records were selected.
set A100 formula DSUM(TESTDB,"TestID",B36:B37) 
test A100 96

# Check for less than a number 
set A101 formula DSUM(TESTDB, "TestID", G36:G37)
test A101 4757

# Two criteria side-by-side are an AND (shall meet ALL criteria)
set A102 formula DSUM(TESTDB, "TestID", B36:C37)
test A102 64

# Two criteria on top of each other are an OR (shall meet ANY of the rows of criteria)
set A103 formula DSUM(TESTDB, "TestID", B36:B38)
test A103 737

# Can have multiple criteria sets 
set A104 formula DSUM(TESTDB, "TestID", B36:C38)
test A104 193

# Can have multiple criteria sets 
set A105 formula DSUM(TESTDB, "TestID", B36:D38)
test A105 0

# Simple text match 
set A106 formula DSUM(TESTDB, "TestID", D36:D37)
test A106 2048

# Date comparison 
set A107 formula DSUM(TESTDB, "TestID", H36:H37)
test A107 3679

# Comparison less than zero 
set A108 formula DSUM(TESTDB, "TestID", E36:E37)
test A108 1580

# Less than or equal to 
set A109 formula DSUM(TESTDB, "TestID", F36:F37)
test A109 8128

# Pair of comparisons, and check on greater than or equal to 
set A110 formula DSUM(TESTDB, "TestID", G36:G38)
test A110 6037

# Matches of field names and text should ignore case if case-sensitive is false 
set A111 formula DSUM(TESTDB, "TestID", H38:H39)
test A111 2048

# If initial text matches, should return it (do not require exact match at higher levels) 
set A112 formula DSUM(TESTDB, "TestID", D38:D39) 
test A112 6144


