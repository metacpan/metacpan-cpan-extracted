#!/usr/bin/perl

# Test cases from Open Formula Specification 1.2 pp169ff
# OpenFormula-v1.2-draft7.odtOpenFormula-v1.2-draft7.odt
# Copyright (C) OASIS Open 2006. All Rights Reserved

use strict;
use warnings;
use lib ('lib', 't/lib');

use SheetTest;
use Test::More tests => 28;

run_tests(against => 't/data/openformula-testsuite.txt');

__DATA__


# A trivial example of DDB.
set A101 formula DDB(4000,500,4,2)
test A101 1000

# Default method is 2 (double declining balance).
set A102 formula DDB(4000,500,4,2,2)
test A102 1000

# Some applications create negative values here.
set A103 formula DDB(1100,100,5,5,2.3)
test A103 0

# A trivial example of FV
set A104 formula FV(10%,12,-100,100)
isnear A104 1824.59

# A trivial example of IRR.
set A105 formula IRR(F24:F26)
isnear A105 0.418787 

# A trivial example of NPER.
set A106 formula NPER(5%,-100,1000)
isnear A106 14.2067

# A trivial example of NPER with non-zero FV.
set A107 formula NPER(5%,-100,1000,100)
isnear A107 15.2067

# A trivial example of NPER with non-zero FV and PayType.
set A108 formula NPER(5%,-100,1000,100,1)
isnear A108 14.2067

# Rate can be zero.
set A109 formula NPER(0,-100,1000)
test A109 10

# Rate can be negative.
set A110 formula NPER(-1%,-100,1000)
isnear A110 9.483283066

# A trivial example of NPV
set A111 formula NPV(100%,4,5,7)
test A111 4.125

# Note that each number in a range is considered separately.
set A112 formula NPV(100%,C4:C6)
test A112 4.125

# A more interesting value. 
set A113 formula NPV(10%,100,200)
isnear A113 256.198347107438 

# A trivial example of PMT.
set A114 formula PMT(5%,12,1000)
isnear A114 -112.82541 

# A trivial example of PMT with non-zero FV.
set A115 formula PMT(5%,12,1000,100)
isnear A115 -119.10795 

# A trivial example of PMT with non-zero FV and PayType.
set A116 formula PMT(5%,12,1000,100,1)
isnear A116 -113.43614 

# Rate can be zero.
set A117 formula PMT(0,10,1000)
test A117 -100

# A trivial example of PV.
set A118 formula PV(10%,12,-100,100)
isnear A118 649.51 

# A trivial example of RATE.
set A119 formula RATE(12,-100,1000)
isnear A119 0.0292285

# A trivial example of RATE with non- zero FV.
set A120 formula RATE(12,-100,1000,100)
isnear A120 0.01623133 

# A trivial example of RATE with non- zero FV and PayType.
set A121 formula RATE(12,-100,1000,100,1)
isnear A121 0.01996455 

# A trivial example of RATE with a guess.
set A122 formula RATE(12,-100,1000,100,1,1%)
isnear A122 0.01996455 

# Nper must be greater than 0.
set A123 formula RATE(0,-100,1000)
iserror A123

# Nper must be greater than 0.
set A124 formula RATE(0,-100,1000)
iserror A124

# A trivial example of SLN. 
set A125 formula SLN(4000,500,4)
test A125 875

# A trivial example of SYD. Note that DDB would have calculated 1000 instead.
set A126 formula SYD(4000,500,4,2)
test A126 1050

# ------ extras ------
#
# IRR with guess
set A127 formula IRR(F24:F26,0.1)
isnear A127 0.418787 

# IRR that doesn't converge
set A128 formula IRR(F24:F26,40)
iserror A128

