#!/usr/bin/perl

# Test cases from Open Formula Specification 1.2 p61
# OpenFormula-v1.2-draft7.odtOpenFormula-v1.2-draft7.odt
# Copyright (C) OASIS Open 2006. All Rights Reserved

use strict;
use warnings;
use lib ('lib', 't/lib');

use SheetTest;
use Test::More tests => 10;

run_tests(against => 't/data/openformula-testsuite.txt');

__DATA__

# Simple reference
set A101 formula B4
test A101 2

# Absolute reference
set A102 formula $B$4
test A102 2

# Partly absolute reference
set A103 formula $B4
test A103 2

# Partly absolute reference
set A104 formula B$4
test A104 2

# Simple range
set A105 formula SUM(B4:B5)
test A105 5

# Explicit sheet name
# set A106 formula Sheet1.B4
TODO test A106 2

# Explicit sheet name, quoted
# set A107 formula 'Sheet1'.B4
TODO test A107 2

# Simple range with explicit Sheet name
# set A108 formula SUM(Sheet1.B4:Sheet1.B5)
TODO test A108 5

# Simple 3D range, naturally with explicit sheet names
# set A109 formula SUM(Sheet1.B4:Sheet2.C5)
TODO test A109 28

# External reference to local IRI. This is a should, not a shall, so an
# application can pass this section without passing this test case.
# set A110 formula './openformula-testsuite.txt'#'Sheet1'.B4
TODO test A110 2

