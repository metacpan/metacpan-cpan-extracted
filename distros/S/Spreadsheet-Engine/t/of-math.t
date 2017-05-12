#!/usr/bin/perl

# Test cases from Open Formula Specification 1.2 pp257ff
# OpenFormula-v1.2-draft7.odtOpenFormula-v1.2-draft7.odt
# Copyright (C) OASIS Open 2006. All Rights Reserved

use strict;
use warnings;
use lib ('lib', 't/lib');

use SheetTest;
use Test::More tests => 87;

run_tests(against => 't/data/openformula-testsuite.txt');

__DATA__

# If less than zero, return negation 
set A101 formula ABS(-4)
test A101 4

# Positive values return unchanged. 
set A102 formula ABS(4)
test A102 4

# arc cosine of SQRT(2)/2 is PI()/4 radians. 
set A103 formula ACOS(SQRT(2)/2)* 4/PI() 
test A103 1 

# TRUE() is 1 if inline. 
set A104 formula ACOS(TRUE())
test A104 0.0

# The result must be between 0.0 and PI(). 
set A105 formula ACOS(-1.0)/PI()
test A105 1

# The argument must be between -1.0 and 1.0. 
set A106 formula ACOS(2.0)
iserror A106

# arc sine of SQRT(2)/2 is PI()/4 radians. 
set A107 formula ASIN(SQRT(2)/2)*4/PI()
isnear A107 1.000000

# arc tangent of 1 is PI()/4 radians. 
set A108 formula ATAN(1)*4/PI()
isnear A108 1.000000

# arc tangent of 1.0/1.0 is PI()/4 radians. 
set A109 formula ATAN2(1,1)*4/PI()
isnear A109 1.000000

# Location of sign makes a difference. 
set A110 formula ATAN2(1,-1)*4/PI()
isnear A110 -1.000000

# Location of sign makes a difference. 
set A111 formula ATAN2(-1,1)*4/PI()
isnear A111 3.000000

# Location of sign makes a difference. 
set A112 formula ATAN2(-1,-1)*4/PI()
isnear A112 -3.000000

# If y is small, it's still important 
# TB *sigh* A level 1 test uses a Level 2 function (SIGN)
set A113 formula IF(ATAN2(-1.0,0.001)>0,1,0)
test A113 1

# If y is small, it's still important 
set A114 formula IF(ATAN2(-1.0,-0.001)<0,1,0)
test A114 1

# By definition ATAN2(-1,0) should give PI() rather than -PI(). 
set A115 formula ATAN2(-1.0,0)/PI()
isnear A115 1.000000

# COS(0) is 1 - require this result to be exact, since documents may depend on it. 
set A116 formula COS(0)
test A116 1

# cosine of PI()/4 radians is SQRT(2)/2. 
set A117 formula COS(PI()/4)*2/SQRT(2)
isnear A117 1.000000

# cosine of PI()/2 radians is 0, the test here gives a little "wiggle room" for computational inaccuracies. "wiggle room" for computational inaccuracies. 
set A118 formula COS(PI()/2)
isnear A118 0.000000

# PI() radians is 180 degrees. 
set A119 formula DEGREES(PI())
test A119 180

# Positive even integers remain unchanged. 
set A120 formula EVEN(6)
test A120 6

# Negative even integers remain unchanged. 
set A121 formula EVEN(-4)
test A121 -4

# Non-even positive integers round up. 
set A122 formula EVEN(1)
test A122 2

# Positive floating values round up. 
set A123 formula EVEN(0.3)
test A123 2

# Non-even negative integers round down. 
set A124 formula EVEN(-1)
test A124 -2

# Negative floating values round down. 
set A125 formula EVEN(-0.3)
test A125 -2

# Anything raised to the 0 power is 1. 
set A126 formula EXP(0)
test A126 1

# The EXP function is the inverse of the LN function. 
set A127 formula EXP(LN(2))
isnear A127 2.000000

# The value of the natural logarithm e. 
set A128 formula EXP(1)
# isnear A128 2.71828182845904523536
isnear A128 2.71828182845904

# Factorial of 0 is 1 
set A129 formula FACT(0)
test A129 1

# Factorial of 1 is 1 
set A130 formula FACT(1)
test A130 1

# Factorial of 2 is 2 
set A131 formula FACT(2)
test A131 2

# Factorial of 3 is 6 
set A132 formula FACT(3)
test A132 6

# Requires F >= 0 
set A133 formula FACT(-1)
TODO iserror A133

# The logarithm of 1 (in any base) is 0. 
set A134 formula LN(1)
test A134 0

# The natural logarithm of e is 1. 
set A135 formula LN(EXP(1))
test A135 1

# Trivial test 
set A136 formula LN(20)
isnear A136 2.995732274

# This tests a value between 0 and 0.5. Values in this domain are valid,
# but implementations that compute LN(x) by blindly summing the series
# (1/n)((x-1)/x)^n won't get this value correct, because that series
# requires x > 0.5. 
set A137 formula LN(0.2)
isnear A137 -1.609437912

# The argument must be greater than zero. 
set A138 formula LN(0)
iserror A138

# The natural logarithm of a non-number gives an error. 
set A139 formula LN(B7)
iserror A139

# The logarithm of 1 (in any base) is 0. 
set A140 formula LOG(1, 10)
test A140 0

# The natural logarithm of 1 is 0. 
set A141 formula LOG(1,EXP(1))
test A141 0

# The base 10 logarithm of 10 is 1. 
set A142 formula LOG(10,10)
test A142 1

# If the base is not specified, base 10 is assumed. 
set A143 formula LOG(10)
test A143 1

# Log base 8 of 8^3 should return 3. 
set A144 formula LOG(8*8*8,8)
test A144 3

# The argument must be greater than zero. 
set A145 formula LOG(0,10)
iserror A145

# The logarithm of 1 (in any base) is 0. 
set A146 formula LOG10(1)
test A146 0

# The base 10 logarithm of 10 is 1. 
set A147 formula LOG10(10)
test A147 1

# The base 10 logarithm of 100 is 2. 
set A148 formula LOG10(100)
test A148 2

# The argument must be greater than zero. 
set A149 formula LOG10(0)
iserror A149

# The logarithm of a non-number gives an error. 
set A150 formula LOG10("H")
iserror A150

# 10/3 has remainder 1. 
set A151 formula MOD(10,3)
test A151 1

# 2/8 is 0 remainder 2. 
set A152 formula MOD(2,8)
test A152 2

# The numbers need not be integers. 
set A153 formula MOD(5.5,2.5)
test A153 0.5

# The location of the sign matters. 
set A154 formula MOD(-2,3)
test A154 1

# The location of the sign matters. 
set A155 formula MOD(2,-3)
test A155 -1

# The location of the sign matters. 
set A156 formula MOD(-2,-3)
test A156 -2

# Division by zero is not allowed 
set A157 formula MOD(10,0)
iserror A157

# Positive odd integers remain unchanged. 
set A158 formula ODD(5)
test A158 5

# Negative odd integers remain unchanged. 
set A159 formula ODD(-5)
test A159 -5

# Non-odd positive integers round up. 
set A160 formula ODD(2)
test A160 3

# Positive floating values round up. 
set A161 formula ODD(0.3)
test A161 1

# Non-odd negative integers round down. 
set A162 formula ODD(-2)
test A162 -3

# Negative floating values round down. 
set A163 formula ODD(-0.3)
test A163 -1

# By definition, ODD(0) is 1. 
set A164 formula ODD(0)
test A164 1

# The approximate value of pi. Lots of digits given here, in case the
# implementation can actually handle that many, but implementations are
# not required to exactly store this many digits.  PI() should return
# the closest possible numeric representation in a fixed-length
# representation. 
set A165 formula PI()
# isnear A165 3.14159265358979323846264338327950
isnear A165 3.14159265358979

# Anything raised to the 0 power is 1. 
set A166 formula POWER(10,0)
test A166 1

# 2^8 is 256. 
set A167 formula POWER(2,8)
test A167 256

# Multiply all the numbers. 
set A168 formula PRODUCT(2,3,4)
test A168 24

# TRUE() is 1 if inline. 
set A169 formula PRODUCT(TRUE(),2,3)
test A169 6

# 2*3 is 6. 
set A170 formula PRODUCT(B4:B5)
test A170 6

# LEVEL 2: In level 2 and higher, conversion to NumberSequence ignores
# strings (in B3) and logical values (a TRUE() in B6). 
set A171 formula PRODUCT(B3:B6)
test A171 6

# LEVEL 2: Product with no parameters returns 0 
set A172 formula PRODUCT()
#test A172 0
TODO testtype A172 n

# 1 180 degrees is PI() radians. 
set A173 formula RADIANS(180)/PI()
test A176

# Sine of 0 is 0, this is required to be exact, since some documents may
# depend on getting this identity exactly correct. 
set A173 formula SIN(0)
test A173 0

# sine of PI()/4 radians is SQRT(2)/2. 
set A174 formula SIN(PI()/4.0)*2/SQRT(2)
isnear A174 1.000000

# sine of PI()/2 radians is 1.
set A175 formula SIN(PI()/2.0)
isnear A175 1.000000

# The square root of 4 is 2. 
set A176 formula SQRT(4)
test A176 2

# The argument must be non-negative 
set A177 formula SQRT(-4)
iserror A177

# Simple sum. 
set A178 formula SUM(1,2,3)
test A178 6

# TRUE() is 1. 
set A179 formula SUM(TRUE(),2,3)
test A179 6

# 2+3 is 5. 
set A180 formula SUM(B4:B5)
test A180 5

# B4 is 2 and B5 is 3, so only B5 has a value greater than 2.5. 
set A181 formula SUMIF(B4:B5,">2.5")
test A181 3

# Test if a cell equals the value in [.B4]. 
set A182 formula SUMIF(B3:B5,B4)
test A182 2

# Constant values are not allowed for the range. 
set A183 formula SUMIF("",B4)
iserror A183

# [.B3] is the string "7", but only numbers are summed. 
set A184 formula SUMIF(B3:B4,"7")
test A184 0

# LEVEL 2: [.B3] is the string "7", but its match is mapped to [.B4] for the summation. 
set A185 formula SUMIF(B3:B4,"7",B4:B5)
test A185 2

# The criteria can be an expression. 
set A186 formula SUMIF(B3:B10,1+1)
test A186 2

# tangent of PI()/4.0 radians. 
set A187 formula TAN(PI()/4.0)
isnear A187 1.000000



