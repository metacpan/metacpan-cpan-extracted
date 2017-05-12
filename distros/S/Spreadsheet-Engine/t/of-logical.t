#!/usr/bin/perl

# Test cases from Open Formula Specification 1.2 pp25ff
# OpenFormula-v1.2-draft7.odtOpenFormula-v1.2-draft7.odt
# Copyright (C) OASIS Open 2006. All Rights Reserved

use strict;
use warnings;
use lib ('lib', 't/lib');

use SheetTest;
use Test::More tests => 42;

run_tests(against => 't/data/openformula-testsuite.txt');

__DATA__

# Simple AND. 
set A101 formula AND(FALSE(),FALSE())
test A101 0

# Simple AND. 
set A102 formula AND(FALSE(),TRUE())
test A102 0

# Simple AND. 
set A103 formula AND(TRUE(),FALSE())
test A103 0

# Simple AND. 
set A104 formula AND(TRUE(),TRUE())
test A104 1

# Returns an error if given one. 
set A105 formula ISNA(AND(TRUE(),NA()))
test A105 1

# Nonzero considered TRUE. 
set A106 formula AND(1,TRUE())
test A106 1

# Zero considered FALSE. 
set A107 formula AND(0,TRUE())
test A107 0

# More than two parameters okay. 
set A108 formula AND(TRUE(),TRUE(),TRUE())
test A108 1

# One parameter okay - simply returns it. 
set A109 formula AND(TRUE())
test A109 1

# Constant 
set A110 formula FALSE()
test A110 0

# Applications that implement logical values as 0/1 must map TRUE() to 1 
# TB: This test seems broken: if a numer is false, then it *will* =0
# thus returning true.
set A111 formula IF(ISNUMBER(FALSE()),FALSE()=0,FALSE()) 
# test A111 0
test A111 1

# TRUE converts to 1 in Number context 
set A112 formula 2+FALSE() 
test A112 2 

# Simple if. 
set A113 formula IF(FALSE(),7,8)
test A113 8

# Simple if. 
set A114 formula IF(TRUE(),7,8)
test A114 7

# Can return strings, and the two sides need not have equal types 
set A115 formula IF(TRUE(),"HI",8)
test A115 HI

# A non-zero is considered true. 
set A116 formula IF(1,7,8)
test A116 7

# A non-zero is considered true. 
set A117 formula IF(5,7,8)
test A117 7

# A zero is considered false. 
set A118 formula IF(0,7,8)
test A118 8

# The result can be a reference. 
set A119 formula IF(TRUE(),B4,8)
test A119 2

# The result can be a formula. 
set A120 formula IF(TRUE(),B4+5, 8)
test A120 7

# Condition has to be convertible to Logical. 
set A121 formula ISERROR(IF("x",7,8))
test A121 1

# Condition has to be convertible to Logical. 
set A122 formula ISERROR(IF("1",7,8))
test A122 1

# Condition has to be convertible to Logical, empty string is not the same as False 
set A123 formula ISERROR(IF("",7,8))
test A123 1

# Default IfFalse is FALSE 
set A124 formula IF(FALSE(),7)
# test A124 0
TODO testtype A124 n

# Default IfTrue is TRUE 
set A125 formula IF(3)
TODO test A125 1

# Empty parameter is considered 0 
set A126 formula IF(FALSE(),7,)
# test A126 0
TODO testtype A126 n

# Empty parameter is considered 0 
set A127 formula IF(TRUE(),,7)
# test A127 0
TODO testtype A127 n

# If condition is true, ifFalse is not considered - even if it would produce Error. 
set A128 formula IF(TRUE(),4,1/0)
test A128 4

# If condition is false, ifTrue is not considered - even if it would produce Error. 
set A129 formula IF(FALSE(),1/0,5)
test A129 5

# Simple NOT, given FALSE. 
set A130 formula NOT(FALSE())
test A130 1

# Simple NOT, given TRUE. 
set A131 formula NOT(TRUE())
test A131 0

# NOT returns an error if given an error value 
set A132 formula ISERROR(NOT(1/0))
test A132 1

# Simple OR. 
set A133 formula OR(FALSE(),FALSE())
test A133 0

# Simple OR. 
set A134 formula OR(FALSE(),TRUE())
test A134 1

# Simple OR. 
set A135 formula OR(TRUE(),FALSE())
test A135 1

# Simple OR. 
set A136 formula OR(TRUE(),TRUE())
test A136 1

# Returns an error if given one. 
set A137 formula ISNA(OR(FALSE(),NA()))
test A137 1

# More than two parameters okay. 
set A138 formula OR(FALSE(),FALSE(),TRUE())
test A138 1

# One parameter okay - simply returns it 
set A139 formula OR(TRUE())
test A139 1

# Constant. 
set A140 formula TRUE()
test A140 1

# Applications that implement logical values as 0/1 must map TRUE() to 1 
set A141 formula IF(ISNUMBER(TRUE()),TRUE()=1,TRUE())
test A141 1

# TRUE converts to 1 in Number context 
set A142 formula 2+TRUE() 
test A142 3 

