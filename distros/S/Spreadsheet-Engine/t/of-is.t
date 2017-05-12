#!/usr/bin/perl

# Test cases from Open Formula Specification 1.2 p217 & p233
# OpenFormula-v1.2-draft7.odtOpenFormula-v1.2-draft7.odt
# Copyright (C) OASIS Open 2006. All Rights Reserved

use strict;
use warnings;
use lib ('lib', 't/lib');

use SheetTest;
use Test::More tests => 32;

run_tests(against => 't/data/openformula-testsuite.txt');

__DATA__


# Numbers return false. 
set A101 formula ISBLANK(1)
test A101 0

# Text, even empty string, returns false. 
set A102 formula ISBLANK("")
test A102 0

# Blank cell is true. 
set A103 formula ISBLANK(B8)
test A103 1

# Non-blank cell is false. 
set A104 formula ISBLANK(B7)
test A104 0

# Error values other than NA() return true. 
set A105 formula ISERR(1/0)
test A105 1

# NA() does NOT return True. 
set A106 formula ISERR(NA())
test A106 0

# Text is not an error. 
set A107 formula ISERR("#N/A")
test A107 0

# Numbers are not an error. 
set A108 formula ISERR(1)
test A108 0

# Error values return true. 
set A109 formula ISERROR(1/0)
test A109 1

# By definition 
# (NA as string bug tested at 5.11)
set A110 ISNA(#N/A)
TODO test A110 1

# Text is not NA
set A111 formula ISNA("#N/A")
test A111 0

# Numbers are not NA
set A112 formula ISNA(1)
test A112 0

# Even NA(). 
set A113 formula ISERROR(NA())
test A113 1

# Text is not an error. 
set A114 formula ISERROR("#N/A")
test A114 0

# Numbers are not an error. 
set A115 formula ISERROR(1)
test A115 0

# If CHOOSE given out-of-range value, ISERROR needs to capture it. 
set A116 formula ISERROR(CHOOSE(0, "Apple", "Orange", "Grape", "Perry"))
test A116 1

# Logical values return true. 
set A117 formula ISLOGICAL(TRUE())
test A117 1

# Logical values return true. 
set A118 formula ISLOGICAL(FALSE())
test A118 1

# Text values are not logicals, even if they can be  
set A119 formula ISLOGICAL("TRUE")
test A119 0

# Error values other than NA() return False - the error does not propagate. 
set A120 formula ISNA(1/0) 
test A120 0 

# By definition 
set A121 formula ISNA(NA())
test A121 1

# Numbers are not text 
set A122 formula ISNONTEXT(1)
test A122 1

# Logical values are not text. 
set A123 formula ISNONTEXT(TRUE ())
test A123 1

# Text values are text, even if they can be converted into a number. 
set A124 formula ISNONTEXT("1")
test A124 0

# B7 is a cell with text 
set A125 formula ISNONTEXT(B7)
test A125 0

# B9 is an error, thus not text 
set A126 formula ISNONTEXT(B9)
test A126 1

# B8 is a blank cell, so this will return TRUE 
set A127 formula ISNONTEXT(B8)
test A127 1

# Numbers are numbers 
set A128 formula ISNUMBER(1)
test A128 1

# Text values are not numbers, even if they can be converted into a number. 
set A129 formula ISNUMBER("1" )
test A129 0

# Numbers are not text 
set A130 formula ISTEXT(1)
test A130 0

# Text values are text, even if they can be converted into a number. 
set A131 formula ISTEXT("1")
test A131 1

#-----------------
# Not in spec

# Paramater errors aren't treated as error when entered directly
set A132 formula ISERROR(LEN())
test A132 1
