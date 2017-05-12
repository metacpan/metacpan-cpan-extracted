#!/usr/bin/perl

# Test cases from Open Formula Specification 1.2 pp83ff, 231, 411ff
# OpenFormula-v1.2-draft7.odtOpenFormula-v1.2-draft7.odt
# Copyright (C) OASIS Open 2006. All Rights Reserved

use strict;
use warnings;
use lib ('lib', 't/lib');

use SheetTest;
use Test::More tests => 80;

run_tests(against => 't/data/openformula-testsuite.txt');

__DATA__

# Inline logical True is converted to 1. 
set A101 formula (1=1)+2 
test A101 3

# Adding forces conversion of TRUE to 1, even if by reference 
set A102 formula B5+B6 
TODO test A102 4

# Since "+" forces a conversion to number, passing "7" to "+" should
# force a conversion to 0, 7, or an error. 
set A103 formula IF(ISERROR("7"+0),TRUE(),OR( ("7"+0)=7, ("7"+0)=0)) 
test A103 1

# B3 is "7"; it should convert to 0, 7, or an error. Note that [.B3]+0
# may produce a different result than inline "7"+0. 
set A104 formula IF(ISERROR(B3+0), TRUE(),OR( (B3+0)=7, (B3+0)=0)) 
test A104 1

# Functions expecting a number but get non-numeric text convert the
# number to 0 or an Error. 
set A105 formula ISERR(IF(COS("hi")=1 ,1/0,0)) 
test A105 1

# Empty cells in a number context are automatically converted into 0. 
set A106 formula 5+B8 
TODO test A106 5

# Conversion to NumberSequence ignores strings (in B3).
set A107 formula SUM(B3:B5)
test A107 5

# If a sequence includes Error, the result has Error.
set A108 formula SUM(B3:B10)
testtype A108 e#VALUE! (missing)

# Nonzero considered True. 
set A109 formula IF(5,TRUE(),FALSE()) 
test A109 1

# Zero considered False. 
set A110 formula IF(0,TRUE(),FALSE()) 
test A110 0

# Blank cells are considered empty
set A111 formula "a"&B8&"b" 
test A111 ab

# Numbers are converted into strings 
set A112 formula "a"&B4&"b" 
test A112 a2b

# N does not change numbers. 
set A113 formula N(6)
test A113 6

# Does convert logicals. 
set A114 formula N(TRUE())
test A114 1

# Does convert logicals. 
set A115 formula N(FALSE())
test A115 0

#----------------

# Trivial comparison. 
set A116 formula EXACT("A","A")
test A116 1

# EXACT, unlike "=", considers different cases different. 
set A117 formula EXACT("A","a")
test A117 0

# EXACT does work with numbers. 
set A118 formula EXACT(1,1)
test A118 1

# Numerical comparisons ignore "trivial" differences that depend only on
# numeric precision of finite numbers. 
set A119 formula EXACT((1/3)*3,1)
test A119 1

# Works with Logical values. 
set A120 formula EXACT(TRUE(), TRUE())
test A120 1

# Different types with different values are different. 
set A121 formula EXACT("1",2)
test A121 0

# If text and number, and text can't be converted to a number, they are
# different and NOT an error. 
set A122 formula EXACT("h",1)
test A122 0

# If text and number, see if number converted to text is equal. 
set A123 formula EXACT("1",1)
test A123 1

# This converts 1 into the Text value "1", the compares and finds that
# it's not the same as " 1" (note the leading space). 
set A124 formula EXACT(" 1",1)
test A124 0

# Simple FIND(). 
set A125 formula FIND("b","abcabc")
test A125 2

# Start changes the start of the search. 
set A126 formula FIND("b","abcabcabc", 3)
test A126 5

# Matching is case-sensitive. 
set A127 formula FIND("b","ABC",1)
iserror A127 

# Simple FIND(), default is 1 
set A128 formula FIND("b","bbbb")
test A128 1

set A129 formula FIND("b","bbbb",2)
test A129 2

# INT(Start) used as starting position 
set A130 formula FIND("b","bbbb",2.9)
test A130 2

# Start >= 0 
set A131 formula FIND("b","bbbb",0)
iserror A131 

set A132 formula FIND("b","bbbb",0.9)
iserror A132 

# Simple LEFT(). 
set A133 formula LEFT("Hello",2)
test A133 He

# INT(), not round to nearest or round towards positive infinity, must
# be used to convert length into an integer. 
set A134 formula LEFT("Hello",2.9)
test A134 He

# Length defaults to 1. 
set A135 formula LEFT("Hello")
TODO test A135 H

# If Length is longer than T, returns T. 
set A136 formula LEFT("Hello",20)
test A136 Hello

# If Length 0, returns empty string. 
set A137 formula LEFT("Hello",0)
test A137 

# Given an empty string, always returns empty string. 
set A138 formula LEFT("",4)
test A138 

# It makes no sense to request a negative number of characters. Also,
# this tests to ensure that INT() is used to convert non-integers to
# integers, if -0.1 were incorrectly rounded to 0 (as it would be by
# round-to- nearest or round-toward-zero), this would incorrectly return
# a null string. 
set A139 formula LEFT("xxx",-0.1)
iserror A139 

# If Length > LEN(T) entire string is returned. 
set A140 formula LEFT("Hello",2^15-1)
test A140 Hello

# Space is a character. 
set A141 formula LEN("Hi There")
test A141 8

# Empty string has zero characters. 
set A142 formula LEN("")
test A142 0

# Numbers are automatically converted. 
set A143 formula LEN(55)
test A143 2

# Uppercase converted to lowercase, other characters just copied to
# result. 
set A144 formula LOWER("HELLObc7")
test A144 hellobc7

# Simple use of MID. 
set A145 formula MID("123456789",5,3)
test A145 567

# If Start is beyond string, return empty string. 
set A146 formula MID("123456789",20,3)
TODO test A146 

# Start cannot be less than one, even if the length is 0 
set A147 formula MID("123456789",-1,0)
iserror A147 

# But otherwise, length=0 produces the empty string 
set A148 formula MID("123456789",1,0)
test A148 

# INT(Start) is used 
set A149 formula MID("123456789",2.9,1 )
test A149 2

# INT(Length) is used 
set A150 formula MID("123456789",2,2.9 )
test A150 23

# The first letter is uppercase and the following letter are lowercase. 
set A151 formula PROPER("hello there")
test A151 Hello There

# The first letter is uppercase and the following letter are lowercase. 
set A152 formula PROPER("HELLO THERE")
test A152 Hello There

# Words are separated by spaces, punctuation, etc. 
set A153 formula PROPER("HELLO.THERE")
test A153 Hello.There

# Replacement text may have different length. 
set A154 formula REPLACE("123456789",5,3,"Q")
test A154 1234Q89

# If Len=0, 0 characters removed. 
set A155 formula REPLACE("123456789",5,0,"Q")
test A155 1234Q56789

# Simple REPT. 
set A156 formula REPT("X",3)
test A156 XXX

# Repeated text can have length > 0. 
set A157 formula REPT("XY",2)
test A157 XYXY

# INT(Count) used if count is a fraction. 
set A158 formula REPT("X",2.9)
test A158 XX

# If Count is zero, empty string. 
set A159 formula REPT("X",0)
test A159 

# If Count is negative, Error. 
set A160 formula REPT("X",-1)
iserror A160 

# Simple RIGHT(). 
set A161 formula RIGHT("Hello",2)
test A161 lo

# Length defaults to 1. 
set A162 formula RIGHT("Hello")
TODO test A162 o

# If Length is longer than T, returns T. 
set A163 formula RIGHT("Hello",20)
test A163 Hello

# If Length 0, returns empty string. 
set A164 formula RIGHT("Hello",0)
test A164 

# If Length is larger than T and is very large, it still returns the
# original short string. 
set A165 formula RIGHT("Hello",2^15-1)
test A165 Hello

# Given an empty string, always returns empty string. 
set A166 formula RIGHT("",4)
test A166 

# Without Which, all replaced. 
set A167 formula SUBSTITUTE("121212","2","ab")
test A167 1ab1ab1ab

# Which starts counting from 1. 
set A168 formula SUBSTITUTE("121212","2","ab",2)
test A168 121ab12

# If not found, returns unchanged. 
set A169 formula SUBSTITUTE("Hello","x","ab")
test A169 Hello

# Returns T if Old is Length 0. 
set A170 formula SUBSTITUTE("xyz","","ab")
test A170 xyz

# Returns T if Old is Length 0, even if T is empty (it does not consider
# an empty T to "match" an empty Old). 
set A171 formula SUBSTITUTE("","","ab")
test A171 

# Which cannot be less than 1. 
set A172 formula SUBSTITUTE("Hello", "H", "J", 0)
iserror A172 

# Simple TRIM(). 
set A173 formula TRIM(" HI ")
test A173 HI

# Multiple spaces become 1 space internally. 
set A174 formula LEN(TRIM("H" & " " & " " & "I"))
test A174 3

# Lowercase converted to upper case, other characters just copied to
# result. copied to result. 
set A175 formula UPPER("Habc7")
test A175 HABC7

# ------
# T does not change text 
set A176 formula T("HI")
test A176 HI

# References transformed
set A177 formula T(B3)
test A177 7

# Non-text converted into null string
set A178 formula T(5)
test A178 

# ------

# EXACT with blank and empty string
set A179 formula EXACT(B8,"")
test A179 1

# But not with blank and zero
set A180 formula EXACT(B8,0)
test A180 0

