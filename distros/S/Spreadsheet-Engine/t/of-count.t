#!/usr/bin/perl

# Test cases from Open Formula Specification 1.2 p217 & p233
# OpenFormula-v1.2-draft7.odtOpenFormula-v1.2-draft7.odt
# Copyright (C) OASIS Open 2006. All Rights Reserved

use strict;
use warnings;
use lib ('lib', 't/lib');

use SheetTest;
use Test::More tests => 15;

run_tests(against => 't/data/openformula-testsuite.txt');

__DATA__


# Simple count. 
set A101 formula COUNT(1,2,3)
test A101 3

# Two numbers in the range. 
set A102 formula COUNT(B4:B5)
test A102 2

# Duplicates are not removed. 
set A103 formula COUNT(B4:B5, B4:B5)
test A103 4

# Errors in referenced cells or ranges are ignored. 
# Spec here has 2. Logical values are meant to not be counted?
set A104 formula COUNT(B4:B9)
TODO test A104 2

set B104 formula COUNT(B6)
TODO test B104 0

# Errors in direct parameters are still ignored. 
# (test changed from spec because of above issue)
set A105 formula COUNT(B4, 1/0)
test A105 1

# Conversion to NumberSequence ignores strings (in B3). 
set A106 formula COUNT(B3:B5)
test A106 2

# Simple count of 3 constant values. 
set A107 formula COUNTA("1",2,TRUE())
test A107 3

# Three non-empty cells in the range. 
set A108 formula COUNTA(B3:B5)
test A108 3

# Duplicates are not removed 
set A109 formula COUNTA(B3:B5,B3:B5)
test A109 6

# Where B9 is "=1/0", i.e. an error, counts the error as non- empty,
# errors contained in a reference do not propogate the error into the
# result. 
set A110 formula COUNTA(B3:B9)
test A110 6

# An error in the list of values is just counted, errors in a constant
# parameter do not propagate. 
set A111 formula COUNTA("1",2,1/0)
test A111 3

# Errors in an evaluated formula do not propagate, they are just counted. 
set A112 formula COUNTA("1",2,SUM(B3:B9))
test A112 3

# Errors in an evaluated formula do not propagate, they are just counted. 
set A113 formula COUNTA("1",2,B3:B9)
test A113 8

# Only B8 is blank. Zero ('0') in B10 is not considered blank. 
set A114 formula COUNTBLANK(B3:B10)
test A114 1


