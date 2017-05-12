#!/usr/bin/perl

# Test cases from Open Formula Specification 1.2 p217 & p233
# OpenFormula-v1.2-draft7.odtOpenFormula-v1.2-draft7.odt
# Copyright (C) OASIS Open 2006. All Rights Reserved

use strict;
use warnings;
use lib ('lib', 't/lib');

use SheetTest;
use Test::More tests => 6;

run_tests(against => 't/data/openformula-testsuite.txt');

__DATA__


# Single cell range contains one column. 
set A101 formula COLUMNS(C1)
test A101 1

# Range with only one column. 
set A102 formula COLUMNS(C1:C4)
test A102 1

# Number of columns in range. 
set A103 formula COLUMNS(A4:D100)
test A103 4

# Single cell range contains one row. 
set A104 formula ROWS(C1)
test A104 1

# Range with four rows. 
set A105 formula ROWS(C1:C4)
test A105 4

# Number of rows in range. 
set A106 formula ROWS(A4:D100)
test A106 97
