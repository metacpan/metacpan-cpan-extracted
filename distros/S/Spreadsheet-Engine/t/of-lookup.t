#!/usr/bin/perl

# Test cases from Open Formula Specification 1.2 pp239ff
# OpenFormula-v1.2-draft7.odtOpenFormula-v1.2-draft7.odt
# Copyright (C) OASIS Open 2006. All Rights Reserved

use strict;
use warnings;
use lib ('lib', 't/lib');

use SheetTest;
use Test::More tests => 20;

run_tests(against => 't/data/openformula-testsuite.txt');

__DATA__

# Simple selection. 
set A101 formula CHOOSE(3,"Apple","Orange","Grape","Perry")
test A101 Grape

# Index has to be at least 1. 
set A102 formula CHOOSE(0,"Apple","Orange","Grape","Perry")
iserror A102

# Index can't refer to non-existent entry. 
set A103 formula CHOOSE(5,"Apple","Orange","Grape","Perry")
iserror A103

# Simple selection, using a set of formulas. 
set A104 formula CHOOSE(2,SUM(B4:B5),SUM(B5))
test A104 3

# CHOOSE can pass references 
set A105 formula SUM(CHOOSE(2,B4:B5,B5))
test A105 3

# First Rev data entry. 
set A106 formula HLOOKUP("Rev",B18:I31,2,FALSE())
test A106 13

# No such value. 
set A107 formula HLOOKUP("NOSUCHNAME", B18:I31,2,FALSE())
iserror A107 

# The result is undetermined since the first row is not sorted
# ascending!  Binary search algorithms may accidentally deliver the
# correct result because in this case "Rev" is the last entry and they
# inspect outermost values first. 
set A108 formula HLOOKUP("Rev",B18:I31,2)
test A108 13

# The result is undetermined since the first row is not sorted ascending! 
# TB: why is it used if it's undetermined!?
# set A109 formula HLOOKUP("NOSUCHNAME",B18:I31,2)
# test A109 12 Mar 2005

# Simple index into row 2, column 1. 
set A110 formula INDEX(B3:C5,2,1)
test A110 2

# Index into row 2, column 1, of area 2 
# TB: We can't construct ranges like this yet
set A111 formula INDEX(B3:C5~B6:C8,2,1,2)
TODO test A111 Hello

# Simple MATCH(). 
set A112 formula MATCH("HELLO",B3:B7,0)
test A112 5

# No value less than or equal to Search in sorted numerical data. 
set A113 formula MATCH(0,B51:B57)
iserror A113 

# In sorted numerical data, 6 is the largest value that is less than or
# equal to Search 
set A114 formula MATCH(6.1,B51:B57)
test A114 3

# Table states Ursa Major has 6 bright stars. 
set A115 formula VLOOKUP("Ursa Major",B19:I31,2,FALSE())
test A115 6

# Table states Ursa Major has abbreviation Uma. 
set A116 formula VLOOKUP("Ursa Major",B19:I31,4,FALSE())
test A116 Uma

# Can match numbers as well as text. Canis Minor is first in table
# (starting from top). 
set A117 formula VLOOKUP(2,C19:I31,3,FALSE())
test A117 Cmi

# Error returned if not found. 
set A118 formula VLOOKUP("NoSuchConstellation", B19:I31,4,FALSE())
iserror A118

# The result is arbitrary because column C (Bright Stars) is not sorted!
# It may match or it may not! 
# TB *Sigh*
# set A119 formula VLOOKUP(2,C19:I31,3)
# test A119 Cmi

# Column B (Constellation) is sorted. "Hercules" is matched because it
# is the largest value less than or equal to "NoSuchConstellation", the
# next larger value would had been "Orion". 
set A120 formula VLOOKUP("NoSuchConstellation", B19:I31,4)
test A120 Her

# No value less than or equal to Lookup in sorted numerical data. 
set A121 formula VLOOKUP(0,B51:B57,2)
iserror A121

# In sorted numerical data, 6 is the largest value that is less than or equal to Lookup.
# (accidentally) fixed when extracting VLOOKUP function 22 Jan 2008
set A122 formula VLOOKUP(6.1,B51:B57,2)
test A122 11

