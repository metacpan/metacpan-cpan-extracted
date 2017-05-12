#!/usr/bin/perl -w
# -*- Mode: perl -*-
#======================================================================
#
# This package is free software and is provided "as is" without
# express or implied warranty.  It may be used, redistributed and/or
# modified under the same terms as perl itself. ( Either the Artistic
# License or the GPL. )
#
# $Id: time.t,v 1.5 2001/07/02 20:43:47 lotr Exp $
#
# (C) COPYRIGHT 2000-2001, Reefknot developers.
#
# See the AUTHORS file included in the distribution for a full list.
#======================================================================

# unit tests for Net::ICal::Time, 
# originally by Chad House <chadh at pobox dot com>

use Test;

#BEGIN { plan tests => 26 }

BEGIN { plan tests => 25 }  # MANY TESTS COMMENTED OUT BECAUSE OF Date::ICal brokenness

use Net::ICal::Time;

# =======================================================================
# NEW DATES WITHOUT TIMES, non-UTC

my $t1 = Net::ICal::Time->new( ical => '19970205');

# make sure that N::I::T is reading in dates properly.
ok($t1->as_ical, '19970205');

# make sure that N::I::T is returning dates correctly broken
# down into elements. 
ok($t1->year,   '1997');
ok($t1->month,  '02');
ok($t1->day,    '05');
ok($t1->hour,   0);
ok($t1->minute, 0);
ok($t1->second, 0);


# ========================================================================
# DATE NORMALIZATION

$t1 = Net::ICal::Time->new(ical => '20010101');
ok($t1->month(15), '3');

# make sure that specifying months larger than 12 rolls the year
# and month over (normalization).

ok($t1->as_ical, ':20020301');

$t1 = Net::ICal::Time->new( ical => '20010101');
ok($t1->day(45), '14');

# make sure that specifying day-of-month larger than 31 rolls the
# month and day over (normalization).
ok($t1->as_ical, ':20010214');


# =======================================================================
# NEW DATES WITH TIMES, non-UTC

my $t2 = Net::ICal::Time->new(ical => '19970101T123545');

# make sure that N::I::T is reading in dates with times correctly.
ok($t2->as_ical, ':19970101T123545');


# ========================================================================
# TIME NORMALIZATION, non-UTC

ok($t2->minute(67), '7');

# make sure that N::I::T is normalizing minutes properly, rolling
# the hour over and adjusting the minutes.
ok($t2->minute,  7);
ok($t2->hour,   13);
ok($t2->second, 45);


# ========================================================================
# NEW DATES WITH TIMES, UTC

my $t3 = Net::ICal::Time->new(ical => '19970101T123545Z');

# make sure that UTC date/times get read in properly.

ok($t3->as_ical, ':19970101T123545Z');

# make sure that UTC times get broken down into components.
# FIXME: do we need to be checking the day, month, and year here?
ok($t3->hour,   12);
ok($t3->minute, 35);
ok($t3->second, 45);


# ========================================================================
# TIME NORMALIZATION, UTC

# make sure that adding 60 minutes really adds one hour. 
$t3->minute($t3->minute + 60);
#ok($t3->as_ical, ':19970101T133545Z');


# ========================================================================
# DAY/DATE ROLLOVER

# XXX TODO : we need tests here to make sure that adding and subtracting
# hours, minutes, and seconds around midnight works properly. 


# ======================================================================
# NEW TIMES FROM INTEGERS

# make sure that building new times from integers works properly.

my $t4 = Net::ICal::Time->new(epoch => 981336499);
ok($t4->as_ical, ':20010205T012819Z');


# =======================================================================
# COMPARISON TESTS

# test to make sure that time comparisons work properly.
# make 2 dates that are different by five minutes;
# $t6 is five minutes after $t5.
my $t5 = Net::ICal::Time->new(ical => '19970101T123545Z');
my $t6 = Net::ICal::Time->new(ical => '19970101T123545Z');
$t6->minute($t6->minute() + 5);

# t5 should be less than t6.
ok($t5->compare($t6), -1);

# t5 should equal t5.
ok($t5->compare($t5),  0);

# t6 should still equal t6. FIXME: do we really need this? if so, why?
ok($t6->compare($t6),  0);

# t6 should be greater than t5.
ok($t6->compare($t5),  1);


# ========================================================================
# CLONING TESTS

#my $t1clone = $t1->clone;

# make sure a clone is exactly the same as its progenitor.
#ok($t1->compare($t1clone), 0);


# ========================================================================
# ARITHMETIC TESTS

# make sure that subtracting times works properly. 

my $t7 = Net::ICal::Time->new(ical => '20000101T120000Z');
my $t8 = Net::ICal::Time->new(ical => '20000102T133030Z');
#my $d1 = $t8->subtract($t7);

# make sure the subtraction came out with the right numbers.
#ok($d1->as_ical, 'P1DT1H30M30S');

# add the difference back to the earlier time (t7) and make
# sure that the result is the same as the later time. 

#my $t9 = $t7->add($d1);
#ok($t9->compare($t8), 0);


# ========================================================================
# END
