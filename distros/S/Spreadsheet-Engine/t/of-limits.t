#!/usr/bin/perl

# Test cases from Open Formula Specification 1.2 p45
# OpenFormula-v1.2-draft7.odtOpenFormula-v1.2-draft7.odt
# Copyright (C) OASIS Open 2006. All Rights Reserved

use strict;
use warnings;
use lib ('lib', 't/lib');

use SheetTest;
use Test::More tests => 4;

run_tests(against => 't/data/openformula-testsuite.txt');

__DATA__

# Functions shall be able to take 30 parameters.
set A100 formula SUM(B4,B5,B4,B5,B4,B5,B4,B5,B4,B5,B4,B5,B4,B5,B4,B5,B4,B5,B4,B5,B4,B5,B4,B5,B4,B5,B4,B5,B4,B5) 
test A100 75

# Formulas can be up to 1024 characters long
set A101 formula B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+B4+B5+1111
test A101 1961

# Strings of ASCII characters can be up to 32767 characters 
set A102 formula LEN(REPT("x";2^15-1)) 
test A102 32767

# Support at least 7 levels of nesting functions. 
set A103 formula SIN(SIN(SIN(SIN(SIN(SIN(SIN(0))))))) 
test A103 0

