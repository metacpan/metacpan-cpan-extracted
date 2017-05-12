#!/usr/bin/perl

# Test cases from Open Formula Specification 1.2 pp431f
# OpenFormula-v1.2-draft7.odtOpenFormula-v1.2-draft7.odt
# Copyright (C) OASIS Open 2006. All Rights Reserved

use strict;
use warnings;
use lib ('lib', 't/lib');

use SheetTest;
use Test::More tests => 11;

run_tests(against => 't/data/openformula-testsuite.txt');

__DATA__

# The "+" operator (which requires numbers) forces the conversion of "7" into 7. 
set A101 formula "7"+0 
test A101 7 

# The "+" operator (which requires numbers) forces the conversion of the reference to the text value "7" into 7. 
set A102 formula B3+0 
test A102 7 

# Function calls requiring Number cause a conversion of text, just like operators do. 
set A103 formula COS("7")=COS(7)
test A103 1 

# Function calls requiring Number cause a conversion of referenced text, just like operators do. 
set A104 formula COS(B3)=COS(7)
test A104 1 

# Adding forces conversion of constant text value "7" on LHS. 
set A105 formula "7"+B4 
TODO test A105 9 

# Adding forces conversion of constant text value "7" on RHS. 
set A106 formula B4+"7" 
test A106 9 

# Adding forces conversion of computed text value "45" on LHS. 
set A107 formula ("4"&"5")+2 
test A107 47 

# Adding forces conversion of computed text value "45" on RHS. 
set A108 formula 2+("4"&"5")
test A108 47 

# Adding forces conversion of referenced text value "7". 
set A109 formula B3+B4 
TODO test A109 9 

# Neither side needs to be numeric; plus itself forces the conversion from text. 
set A110 formula B3+B6 
TODO test A110 8 

# Dates are converted too. 
set A111 formula ("2006-05-21"+0)=DATE(2006,5,21)
test A111 1 


