#!/usr/bin/perl

# Test cases from Open Formula Specification 1.2 pp121ff
# OpenFormula-v1.2-draft7.odtOpenFormula-v1.2-draft7.odt
# Copyright (C) OASIS Open 2006. All Rights Reserved

use strict;
use warnings;
use lib ('lib', 't/lib');

use SheetTest;
use Test::More tests => 54;

run_tests(against => 't/data/openformula-testsuite.txt');

__DATA__

# Simple date value. 
set A101 formula DATE(2005,1,31)=C7
test A101 1

# differences are computed correctly. 
set A102 formula DATE(2005,12,31)-DATE(1904,1,1) 
test A102 37255

# 2004 was a leap year. 
set A103 formula DATE(2004,2,29)=DATE(2004,2,28)+1 
test A103 1

# 2000 was a leap year. 
set A104 formula DATE(2000,2,29)=DATE(2000,2,28)+1 
test A104 1 
# 2005 was not a leap year. 
set A105 formula DATE(2005,3,1)=DATE(2005,2,28)+1 
test A105 1

# Fractional values for year are truncated 
set A106 formula DATE(2017.5,1,2)=DATE(2017,1,2) 
test A106 1

# Fractional values for month are truncated 
set A107 formula DATE(2006,2.5,3)=DATE(2006,2,3) 
test A107 1

# Fractional values for day are truncated 
set A108 formula DATE(2006,1,3.5)=DATE(2006,1,3) 
test A108 1

# Months > 12 roll over to year 
set A109 formula DATE(2006,13,3)=DATE(2007,1,3) 
test A109 1

# Days greater than month limit roll over to month 
set A110 formula DATE(2006,1,32)=DATE(2006,2,1) 
test A110 1

# Days and months roll over transitively 
set A111 formula DATE(2006,25,34)=DATE(2008,2,3)
# we get =DATE(2008,2,5)
TODO test A111 1

# Negative months roll year backward 
set A112 formula DATE(2006,-1,1)=DATE(2005,11,1) 
test A112 1

# Negative days roll month backward 
set A113 formula DATE(2006,4,- 1)=DATE(2006,3,30) 
test A113 1

# Negative days and months roll backward transitively 
set A114 formula DATE(2006,-4,- 1)=DATE(2005,7,30) 
test A114 1

# Non-leap year rolls forward 
set A115 formula DATE(2003,2,29)=DATE(2003,3,1)
test A115 1

# Basic extraction. 
set A116 formula DAY(DATE(2006;5;21)) 
test A116 21 

# Text allowed too, since it's a DateParam 
set A117 formula DAY("2006-12-15") 
test A117 15 

# 5/24ths of a day is 5 hours, aka 5AM
set A118 formula HOUR(5/24)
test A118 5

# 1 second before 5AM, it's 4AM. 
set A119 formula HOUR(5/24-1/(24*60*60))
test A119 4

# TimeParam accepts text
set A120 formula HOUR("14:00") 
test A120 14 

# 1 minute is 1/(24*60) of a day. 
set A121 formula MINUTE(1/(24*60)) 
test A121 1 

# If you start with today, and add a minute, you get a minute. 
set A122 formula MINUTE(TODAY()+1/(24*60)) 
test A122 1 

# At the beginning of the hour, we have 0 minutes. 
set A123 formula MINUTE(1/24) 
test A123 0 

# Month extraction from date in cell.
set A124 formula MONTH(C7)
test A124 1

# Month extraction from DATE() value
set A125 formula MONTH(DATE(2006,5,21))
test A125 5

# NOW constantly changes, but we know it's beyond this date. 
set A126 formula NOW()>DATE(2006,1,3) 
test A126 1

# NOW() is part of TODAY(). WARNING: this test is allowed to fail if the
# locale transitions through midnight while computing this test,this
# failure is incredibly unlikely to occur in practice. 
set A127 formula INT(NOW())=TODAY() 
test A127 1

# This is one second into today. 
set A128 formula SECOND(1/(24*60*60)) 
test A128 1

# Rounds. 
set A129 formula SECOND(1/(24*60*60*2)) 
test A129 1

# Rounds. 
set A130 formula SECOND(1/(24*60*60*4)) 
test A130 0

# All zero arguments becomes midnight, 12:00:00 AM. 
set A131 formula TIME(0,0,0) 
test A131 0

# This is 11:59:59 PM. 
set A132 formula TIME(23,59,59)*60*60*24 
test A132 86399 

# Seconds and minutes roll over transitively,this is 1:07:24 PM. 
set A133 formula TIME(11,125,144)*60*60*24 
# TODO this fails an equlity test...
isnear A133 47244.000000

# Negative seconds roll minutes backwards, 10:58:03 AM 
set A134 formula TIME(11,0,-117)*60*60*24 
test A134 39483 

# Negative minutes roll hours backwards, 9:03:00 AM 
set A135 formula TIME(11,-117,0)*60*60*24 
test A135 32580 

# Negative seconds and minutes roll backwards transitively, 8:52:36 AM 
# (Spec is incorrect here, wanting negative time)
set A136 formula TIME(11,-125,-144)*60*60*24 
test A136 31956 

# Every date TODAY() changes, but we know it's beyond this date. 
set A137 formula TODAY()>DATE(2006,1,3) 
test A137 1

# TODAY() returns an integer. WARNING: this test is allowed to fail if
# the locale transitions through midnight while computing this
# test,because TODAY() is referenced twice, in some implementations this
# would result in a race condition) This is incredibly unlikely to occur
# in practice. 
set A138 formula INT(TODAY())=TODAY() 
test A138 1

# Year-month-date format 
set A139 formula WEEKDAY(DATE(2006,5,21)) 
test A139 1

# Saturday. 
set A140 formula WEEKDAY(DATE(2005,1,1)) 
test A140 7

# Saturday. 
set A141 formula WEEKDAY(DATE(2005,1,1),1) 
test A141 7

# Saturday. 
set A142 formula WEEKDAY(DATE(2005,1,1),2) 
test A142 6

# Saturday. 
set A143 formula WEEKDAY(DATE(2005,1,1),3) 
test A143 5

# Extracts year from a given date. 
set A144 formula YEAR(DATE(1904,1,1)) 
test A144 1904

# --------------------------------


# The year 1900 was not a leap year, so the difference between these two dates is one day 
set A145 formula DATE(1900,3,1)-DATE(1900,2,28)
test A145 1 

# The year 1583 was an ordinary 365-day year 
set A146 formula DATE(1584,1,1)-DATE(1583,1,1)
test A146 365 

# The year 1584 is divisible by 4, and thus was a leap year. 
set A147 formula DATE(1585,1,1)-DATE(1584,1,1)
test A147 366 

# 1600: Leap year 
set A148 formula DATE(1601,1,1)-DATE(1600,1,1)
test A148 366 

# 1700: Not a leap year 
set A149 formula DATE(1701,1,1)-DATE(1700,1,1)
test A149 365 

# 1800: Not a leap year 
set A150 formula DATE(1801,1,1)-DATE(1800,1,1)
test A150 365 

# 1900: Not a leap year 
set A151 formula DATE(1901,1,1)-DATE(1900,1,1)
test A151 365 

# 2000: Leap year 
set A152 formula DATE(2001,1,1)-DATE(2000,1,1)
test A152 366 

# 2100: Not a leap year 
set A153 formula DATE(2101,1,1)-DATE(2100,1,1)
test A153 365 

# Show that calculations can be correct starting from January 1, 1583. 
set A154 formula DATE(2000,1,1)-DATE(1583,1,1)
test A154 152306
