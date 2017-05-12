#!/usr/bin/perl

# Test cases from Open Formula Specification 1.2 pp324ff
# OpenFormula-v1.2-draft7.odtOpenFormula-v1.2-draft7.odt
# Copyright (C) OASIS Open 2006. All Rights Reserved

use strict;
use warnings;
use lib ('lib', 't/lib');

use SheetTest;
use Test::More tests => 27;

run_tests(against => 't/data/openformula-testsuite.txt');

__DATA__

# Simple average. 
set A101 formula AVERAGE(2,4)
test A101 3

# Negative numbers are smaller than positive numbers. 
set A102 formula MAX(2,4,1,-8)
test A102 4

# The maximum of (2,3) is 3. 
set A103 formula MAX(B4:B5)
test A103 3

# Inline errors are propagated. 
set A104 formula ISNA(MAX(NA()))
test A104 1

# Strings are not converted to numbers and are ignored. 
set A105 formula MAX(B3:B5)
test A105 3

# Strings are not converted to numbers and are ignored. 
set A106 formula MAX(-1,B7)
test A106 -1

# Errors inside ranges are NOT ignored. 
set A107 formula MAX(B3:B9)
iserror A107 

# Negative numbers are smaller than positive numbers. 
set A108 formula MIN(2,4,1,-8)
test A108 -8

# The minimum of (2,3) is 2. 
set A109 formula MIN(B4:B5)
test A109 2

# If no numbers are provided in all ranges, MIN returns 0 
set A110 formula MIN(B3)
test A110 0

# Non-numbers inline are NOT ignored. 
set A111 formula MIN("a")
TODO iserror A111 

# Cell text is not converted to numbers and is ignored. 
set A112 formula MIN(B3:B5)
test A112 2

# The sample standard deviation of (2,4) is SQRT(2). 
set A113 formula STDEV(2,4)/SQRT(2)
test A113 1

# The sample standard deviation of (2,3) is 1/SQRT(2). 
set A114 formula STDEV(B4:B5)*SQRT(2)
isnear A114 1.000000

# Strings are not converted to numbers and are ignored. 
set A115 formula STDEV(B3:B5)*SQRT(2)
isnear A114 1.000000

# Ensure that implementations use a reasonably stable way of calculating STDEV. 
set A116 formula STDEV(10000000001,10000000002,10000000003,10000000004,10000000005,10000000006,10000000007,10000000008,10000000009,10000000010)
isnear A116 3.027650

# At least two numbers must be included 
set A117 formula STDEV(1)
iserror A117 

# The standard deviation of the set for (2,4) is 1. 
set A118 formula STDEVP(2,4)
test A118 1

# The standard deviation of the set for (2,3) is 0.5
set A119 formula STDEVP(B4:B5)*2
test A119 1

# Strings are not converted to numbers and are ignored. 
set A120 formula STDEVP(B3:B5)*2 
test A120 1

# STDEVP(1) is 0. 
set A121 formula STDEVP(1)
test A121 0

# The sample variance of (2,4) is 2. 
set A122 formula VAR(2,4)
test A122 2

# The sample variance of (2,3) is 0.5
set A123 formula VAR(B4:B5)*2 
test A123 1

# Strings are not converted to numbers and are ignored. 
set A124 formula VAR(B3:B5)*2 
test A124 1

# The variance of the set for (2,4) is 1. 
set A125 formula VARP(2,4)
test A125 1

# The variance of the set for (2,3) is 0.25
set A126 formula VARP(B4:B5)*4 
test A126 1

# Strings are not converted to numbers and are ignored. 
set A127 formula VARP(B3:B5)*4 
test A127 1

