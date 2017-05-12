#!/usr/bin/perl

# Test cases from Open Formula Specification 1.2 p61
# OpenFormula-v1.2-draft7.odtOpenFormula-v1.2-draft7.odt
# Copyright (C) OASIS Open 2006. All Rights Reserved

use strict;
use warnings;
use lib ('lib', 't/lib');

use SheetTest;
use Test::More tests => 5;

run_tests();

__DATA__
# Syntactically this is a zero-parameter function call, not a
# one-parameter function call whose parameter happens to be empty.
# Implementations will typically treat TRUE() as a constant.
set A101 formula TRUE()
test A101 1

# One parameter
set A102 formula ABS(4)
test A102 4

# Two parameters 
set A103 formula MAX(2,3)
test A103 3

# Simple if, three parameters
set A104 formula IF(FALSE(),7,8)
test A104 8

# Empty parameter for "else" parameter is considered 0 by IF
set A105 formula IF(FALSE(),7,)
TODO testtype A105 n

