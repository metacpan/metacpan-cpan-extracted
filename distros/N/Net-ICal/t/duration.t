#!/usr/bin/perl -w
# -*- Mode: perl -*-
#======================================================================
#
# This package is free software and is provided "as is" without
# express or implied warranty.  It may be used, redistributed and/or
# modified under the same terms as perl itself. ( Either the Artistic
# License or the GPL. )
#
# $Id: duration.t,v 1.5 2001/05/10 13:08:11 coral Exp $
#
# (C) COPYRIGHT 2000-2001, Reefknot developers.
#
# See the AUTHORS file included in the distribution for a full list.
#======================================================================

# unit tests for Net::ICal::Duration,
# originally by Chad House <chadh at pobox dot com>

use Test;

BEGIN { plan tests => 23 }

use Net::ICal::Duration;


# Constructor tests w/ strings

my $d1 = Net::ICal::Duration->new('P15DT5H0M20S');
ok($d1->as_ical_value, 'P2W1DT5H20S');
ok($d1->as_int, 15*24*60*60 + 5*60*60 + 20);

my $d2 = Net::ICal::Duration->new('P15D');
ok($d2->as_ical_value, 'P2W1D');
ok($d2->as_int, 15*24*60*60);

my $d3 = Net::ICal::Duration->new('P7W');
ok($d3->as_ical_value, 'P7W');
ok($d3->as_int, 7*7*24*60*60);

my $d4 = Net::ICal::Duration->new('P1W3DT30M5S');
ok($d4->as_ical_value, 'P1W3DT30M5S');
ok($d4->as_int, 10*24*60*60 + 30*60 + 5);

my $d5 = Net::ICal::Duration->new('PT3M10S');
ok($d5->as_ical_value, 'PT3M10S');
ok($d5->as_int, 3*60 + 10);

# Constructor tests w/ ints

my $d6 = Net::ICal::Duration->new(2 * (60*60*24) +
                                  3 * (60*60) +
                                  4 * (60) +
                                  5);

ok($d6->as_ical_value, 'P2DT3H4M5S');
ok($d6->as_int, 183845);

# Negative durations (needed for Alarms)

my $dneg = Net::ICal::Duration->new('-PT10M');
ok($dneg->as_ical_value, '-PT10M');
ok($dneg->as_int, -10*60);

# Cloning

my $d6clone = $d6->clone;
ok($d6->as_ical_value, $d6clone->as_ical_value);


# Addition

my $d7 = Net::ICal::Duration->new('P2DT3H4M5S');

ok($d1->add($d7)->as_ical_value, 'P2W3DT8H4M25S');
ok($d2->add($d7)->as_ical_value, 'P2W3DT3H4M5S');


# Subtraction

ok($d1->subtract($d7)->as_ical_value, 'P1W6DT1H56M15S');

my $datefoo = Net::ICal::Duration->new('P4D');
ok($datefoo->subtract($d7)->as_ical_value, 'P1DT20H55M55S');

# No time at all

my $d8 = Net::ICal::Duration->new('P0DT0H0M0S');
ok($d8->as_ical_value, 'PT0S');

my $d9 = Net::ICal::Duration->new('-P0DT0H0M0S');
ok($d9->as_ical_value, 'PT0S');

my $d10 = Net::ICal::Duration->new('PT');
ok($d10->as_ical_value, 'PT0S');

my $d11 = Net::ICal::Duration->new('-PT');
ok($d11->as_ical_value, 'PT0S');

# TODO: rewrite the as_ical function in Duration to be a child class of 
# Property and write tests against that function. 
