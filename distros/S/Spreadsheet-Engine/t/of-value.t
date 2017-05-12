#!/usr/bin/perl

# Test cases from Open Formula Specification 1.2 pp238f
# OpenFormula-v1.2-draft7.odtOpenFormula-v1.2-draft7.odt
# Copyright (C) OASIS Open 2006. All Rights Reserved

use strict;
use warnings;
use lib ('lib', 't/lib');

use SheetTest;
use Test::More tests => 23;

run_tests(against => 't/data/openformula-testsuite.txt');

__DATA__

# VALUE converts text to numbers (unlike N). 
set A101 formula VALUE("6")
test A101 6

# Works with exponential notation. 
set A102 formula VALUE("1E5")
test A102 100000

# Optional %. 
set A103 formula VALUE("200%")
test A103 2

# LOCALE-DEPENDENT: Accepts fractional values. In en_US, this is valid. 
set A104 formula VALUE("1.5")
test A104 1.5

# Fractional part. 
set A105 formula VALUE("7 1/4")
test A105 7.25

# Fractional part. 
set A106 formula VALUE("0 1/2")
test A106 0.5

# -1 1/2 is interpreted as -1.5, not as (-1)+(1 / 2). 
set A107 formula VALUE("-1 1/2")
TODO test A107 -1.5

# VALUE converts references to text to numbers. 
set A108 formula VALUE(B3)
test A108 7

# VALUE converts time values to numbers between 0 and 1. 
set A109 formula VALUE("00:00")
test A109 0

# VALUE converts time values to numbers between 0 and 1. 
set A110 formula VALUE("02:00")-2/24 
isnear A110 0.0

# Time value with hours and minutes. 
set A111 formula VALUE("2:03")-(2/24)- (3/(24*60))
isnear A111 0.0

# Hours, minutes, and seconds. 
set A112 formula VALUE("2:03:05")-2/24-3/(24*60)-5/(24*60*60) 
isnear A112 0.0

# Invalid date yields an error (contrast this with DATE) 
set A113 formula VALUE("3/32/2006")
TODO iserror A113 

# "False leap year" yields an error for 1901 and beyond 
set A114 formula VALUE("2/29/2006")
TODO iserror A114

# VALUE converts dates into serial numbers. 
set A115 formula VALUE("2005-01-02")=DATE(2005,1,2)
test A115 1

# Datetime values handled correctly, using space to separate date from
# time. Note that VALUE can return portions of a day, unlike DATEVALUE
# or TIMEVALUE. 
set A116 formula VALUE("2005-01-03 13:00")-VALUE("2005-01-02 01:00")
TODO test A116 1.5

# Datetime values handled correctly, using 'T' to separate date from
# time as defined by ISO 8601. 
set A117 formula VALUE("2005-01-03T13:00")-VALUE("2005-01-02T01:00")
TODO test A117 1.5

# LOCALE-DEPENDENT, in en_US, this is true. 
set A118 formula VALUE("1/2/2005")=DATE(2005,1,2)
test A118 1

# LOCALE-DEPENDENT, Short year format with slashes 
set A119 formula VALUE("5/21/06")=DATE(2006,5,21)
test A119 1

# LOCALE-DEPENDENT, Short alphabetic month day, year 
set A120 formula VALUE("Oct 29, 2006")=DATE(2006,10,29)
TODO test A120 1

# LOCALE-DEPENDENT, Short alphabetic day month year 
set A121 formula VALUE("29 Oct 2006")=DATE(2006,10,29)
TODO test A121 1

# LOCALE-DEPENDENT, Long alphabetic month day, year 
set A122 formula VALUE("October 29, 2006")=DATE(2006,10,29)
TODO test A122 1

# LOCALE-DEPENDENT, Long alphabetic day month year 
set A123 formula VALUE("29 October 2006")=DATE(2006,10,29)
TODO test A123 1

