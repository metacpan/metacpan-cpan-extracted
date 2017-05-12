#!/usr/bin/perl

# Test cases from Open Formula Specification 1.2 pp317ff
# OpenFormula-v1.2-draft7.odtOpenFormula-v1.2-draft7.odt
# Copyright (C) OASIS Open 2006. All Rights Reserved

use strict;
use warnings;
use lib ('lib', 't/lib');

use SheetTest;
use Test::More tests => 27;

run_tests(against => 't/data/openformula-testsuite.txt');

__DATA__

# Positive integers remain unchanged 
set A101 formula INT(2)
test A101 2

# Negative integers remain unchanged 
set A102 formula INT(-3)
test A102 -3

# Positive floating values are truncated 
set A103 formula INT(1.2)
test A103 1

# It doesn¿t matter if the fractional part is > 0.5 
set A104 formula INT(1.7)
test A104 1

# Negative floating values round towards negative infinity 
set A105 formula INT(-1.2)
test A105 -2

# Naive users expect INT to "correctly" make integers even if there are
# limits on precision. 
set A106 formula INT((1/3)*3 )
test A106 1

# If b is not specified, round to the nearest integer. 
set A107 formula ROUND(10.1, 0)
test A107 10

# Round to nearest value (different than INT) 
set A108 formula ROUND(9.8,0)
test A108 10

# .5 rounds up, away from zero. 
set A109 formula ROUND(0.5, 0)
test A109 1 

# Round to the nearest integer. 
set A110 formula ROUND(1/3,0)
test A110 0

# Round to one decimal place. 
set A111 formula ROUND(1/3,1)
test A111 0.3

# Round to two decimal places. 
set A112 formula ROUND(1/3,2)
test A112 0.33

# If b is not an integer, it is truncated. 
set A113 formula ROUND(1/3,2.9)
test A113 0.33

# Round to the nearest 10. 
set A114 formula ROUND(5555,-1)
test A114 5560

# Negative number rounded to the nearest integer 
set A115 formula ROUND(-1.1, 0)
test A115 -1

# Negative number rounds away from zero 
set A116 formula ROUND(-1.5, 0)
test A116 -2

# Default precision is 0 
set A117 formula ROUND(-1.5)
test A117 -2

set A118 formula ROUND(1.1)
test A118 1

set A119 formula ROUND(9.8)
test A119 10

# If b is not specified, truncate to the nearest integer. 
set A120 formula TRUNC(10.1)
TODO test A120 10

# Truncate rather than rounding. 
set A121 formula TRUNC(0.5)
# test A121 0
TODO testtype A121 n

# Truncate to an integer. 
set A122 formula TRUNC(1/3,0)
test A122 0

# Truncate to one decimal place. 
set A123 formula TRUNC(1/3,1)
test A123 0.3

# Truncate to two decimal places. 
set A124 formula TRUNC(1/3,2)
test A124 0.33

# If b is not an integer, it is truncated. 
set A125 formula TRUNC(1/3,2.9)
test A125 0.33

# Truncate to the nearest 10. 
set A126 formula TRUNC(5555,-1)
test A126 5550

# Negative number truncated to an integer 
set A127 formula TRUNC(-1.1,0)
test A127 -1

