#!/usr/bin/perl

# Test cases from Open Formula Specification 1.2 p77
# OpenFormula-v1.2-draft7.odtOpenFormula-v1.2-draft7.odt
# Copyright (C) OASIS Open 2006. All Rights Reserved

use strict;
use warnings;
use lib ('lib', 't/lib');

use SheetTest;
use Test::More tests => 3;

run_tests();

__DATA__

# Whitespace permitted 
set A101 formula 3.5 + 3 
test A101 6.5

# Whitespace permitted around ordinary parentheses used for grouping 
set A102 formula ( 2 + 3 ) * 5 
test A102 25

# Percent is not special; it can be surrounded by whitespace too 
set A103 formula 300 % 
test A103 3

