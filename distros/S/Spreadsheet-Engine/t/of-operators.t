#!/usr/bin/perl

# Test cases from Open Formula Specification 1.2 pp89ff
# OpenFormula-v1.2-draft7.odtOpenFormula-v1.2-draft7.odt
# Copyright (C) OASIS Open 2006. All Rights Reserved

use strict;
use warnings;
use lib ('lib', 't/lib');

use SheetTest;
use Test::More tests => 68;

run_tests(against => 't/data/openformula-testsuite.txt');

__DATA__

# Simple addition
set A101 formula 1+2
test A101 3

# 2+3 is 5
set A102 formula B4+B5
test A102 5

# Simple subtraction
set A103 formula 3-1
test A103 2

# 1 3-2 is 1
set A104 formula B5-B4

# Subtraction can be combined with unary minus
set A105 formula 5 - - 2
TODO test A105 7

# Subtraction can be combined with unary minus, even without spaces
set A106 formula 5--2
test A106 7

# Left-to-right associative
set A107 formula 3-2+3
test A107 4

# Difference of two dates is the number of days between them
set A108 formula C8-C7
test A108 365

# Simple multiplication
set A109 formula 3*4
test A109 12

# 2*3 is 6
set A110 formula B4*B5
test A110 6

# Multiplication has a higher precedence than addition
set A111 formula 2+3*4
test A111 14

# Simple division
set A112 formula 6/3
test A112 2

# Division is left-to-right associative
set A113 formula 144/3/2
test A113 24

# Division and multiplication are left-to-right
set A114 formula 6/3*2
test A114 4

# Division has a higher precedence than +
set A115 formula 2+6/2
test A115 5

# Simple division; fractional values are possible
set A116 formula 5/2
test A116 2.5

# Dividing by zero is not allowed
set A117 formula ISERROR(1/0)
test A117 1

# Simple exponentiation
set A118 formula 2^3
test A118 8

# Raising to the 0.5 power is the same as a square root
set A119 formula 9^0.5
test A119 3

# Must be able to accept Left < 0
set A120 formula (-5)^3
test A120 -125

# Must be able to accept Right < 0
set A121 formula 4^-1
test A121 0.25

# 1 Raising nonzero to the zeroth power results in 1
set A122 formula 5^0
test A122 1

# Raising zero to nonzero power results in 0
set A123 formula 0^5
test A123 0

# Precedence: ^ is higher than *, which is higher than +
set A124 formula 2+3*4^2
test A124 50

# Unary "-" has a higher precedence than "^"
set A125 formula -2^2
test A125 4

# 8^2 is the square of 8
set A126 formula (2^3)^2
test A126 64

# 2 to the ninth power
set A127 formula 2^(3^2)
test A127 512

# "^" is left-associative, not right-associative
set A128 formula 2^3^2
test A128 64

# Trivial comparison
set A129 formula 1=1
test A129 1

# References are converted into numbers, and then compared
set A130 formula B4=2
test A130 1

# Trivial comparison
set A131 formula 1=0
test A131 0

# Grossly wrong equality results are not acceptable.  Spreadsheets
# cannot "pass" automated tests by simply making "=" always return TRUE
# when it's even slightly close
set A132 formula 3=3.0001
test A132 0

# Trivial text comparison - no match
set A133 formula "Hi"="Bye"
test A133 0

# Can compare logical values
set A134 formula FALSE()=FALSE( )
test A134 1

# Can compare logical values
set A135 formula TRUE()=FALSE()
test A135 0

# Different types are not equal
set A136 formula "5"=5
TODO test A136 0

# If there's an error on either side, the result is an error -- even if
# you're comparing the "same" error on both sides
set A137 formula ISNA(NA()=NA())
test A137 1

# Note, this is only true if table:case-sensitive is false
set A138 formula "Hi"="HI"
test A138 1

# 1 really is 1
set A139 formula 1<>1
test A139 0

# 1 is not 2
set A140 formula 1<>2
test A140 1

# Text and Number have different types
set A141 formula 1<>"1"
TODO test A141 1

# Text comparison ignores case distinctions. Note, this is only true if
# table:case- sensitive is false
set A142 formula "Hi"<>"HI"
test A142 0

# This operator cannot compare error values to determine if they are the
# same error. If either side is an error, the result is an error
set A143 formula ISERROR(1/0=1/0)
test A143 1

# Trivial comparison
set A144 formula 5<6
test A144 1

# Trivial comparison
set A145 formula 5<=6
test A145 1

# Trivial comparison
set A146 formula 5>6
test A146 0

# Trivial comparison
set A147 formula 5>=6
test A147 0

# Trivial comparison of text
set A148 formula "A"<"B"
test A148 1

# True when table:case-sensitive is false
set A149 formula "a"<"B"
test A149 1

# Longer text is "larger" than shorter text, if they match in case-
# insensitive way through to the end of the shorter text
set A150 formula "AA">"A"
test A150 1

# This isn't a range operation in ODF; it's just a cell specifier, with
# a range embedded. The result is the same, though
set A151 formula SUM(B4:B5)
test A151 5

# Simple range creation. Note the range OUTSIDE the .. markers
# TODO this makes no sense without [.B4]:[.B5] syntax!
set A152 formula SUM(B4:B5)
test A152 5

# Range can extend an existing range, this is the same as SUM(.B4:C5))
set A153 formula SUM((B4:C4:C5))
TODO test A153 14

# Simple concatenation
set A154 formula "Hi " & "there"
test A154 Hi there
set B154 formula "Hi "&"there"
test B154 Hi there

# Concatenating an empty string produces no change
set A155 formula "H"&""
test A155 H

# Unary "-" has higher precedence than "&"
set A156 formula -5&"b"
test A156 -5b

# Binary "-" has higher precedence than "&"
set A157 formula 3&2-1
test A157 31

# Simple intersection; reference result is B5, and SUM simply sums that
# one number (3) and returns it
set A158 formula SUM((B3:B5!B5:B6))
TODO test A158 3

# Range and intersection have a higher precedence than unary minus
set A159 formula 4+(-B4:C5!B4)
TODO test A159 2

# Simple percent value
set A160 formula 50%
test A160 0.5

# Percent does not change the meaning of other operations; this is not 30
set A161 formula 20+50%
test A161 20.5

# Percent has a higher precedence than "^"
set A162 formula 3^200%
test A162 9

# Percent can be used as a general operator
set A163 formula B4%
test A163 0.02

# Numbers don't change
set A164 formula +5
test A164 5

# Does not convert a string to a number
set A165 formula +"Hello"
TODO test A165 Hello

# Negated 2 is -2
set A166 formula -B4
test A166 -2

# Negative numbers are fine
set A167 formula -2=(0-2)
test A167 1

#-------------------------
# Not from spec (TODO move to another file)

set B101 formula 1+TRUE()
test B101 2

