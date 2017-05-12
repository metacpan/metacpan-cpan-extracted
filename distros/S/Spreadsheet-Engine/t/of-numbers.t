#!/usr/bin/perl

# Test cases from Open Formula Specification 1.2 p60
# OpenFormula-v1.2-draft7.odtOpenFormula-v1.2-draft7.odt
# Copyright (C) OASIS Open 2006. All Rights Reserved

use strict;
use warnings;
use lib ('lib', 't/lib');

use SheetTest;
use Test::More tests => 5;

run_tests();

__DATA__

# Numbers use "." as the decimal separator; trivial fractions supported.
set A100 formula 56.5
test A100 56.5

# Readers accept initial "." for constant numbers, but should not write them.
set A101 formula .5
test A101 0.5

# Exponents can be negative
set A102 formula 550E-1
test A102 55

# Exponents can be positive
set A103 formula 550E+1
test A103 5500

# Exponents can have no sign (+ assumed) and lowercase "e" is okay
set A104 formula 56e2
test A104 5600

