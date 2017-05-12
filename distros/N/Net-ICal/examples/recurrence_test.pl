#!/usr/bin/perl -w
# -*- Mode: perl -*-
#======================================================================
#
# This package is free software and is provided "as is" without
# express or implied warranty.  It may be used, redistributed and/or
# modified under the same terms as perl itself. ( Either the Artistic
# License or the GPL. )
#
# $Id: recurrence_test.pl,v 1.6 2001/07/23 15:09:50 lotr Exp $
#
# (C) COPYRIGHT 2000-2001, Reefknot developers.
#
# See the AUTHORS file included in the distribution for a full list.
#======================================================================

# recurrence_test.pl: demonstrates the use of the Recurrence 
# and Recurrence classes.

use strict;
use lib '../lib';

use POSIX qw(strftime);

use Net::ICal;

my $organizer = Net::ICal::Attendee->new('shutton');
my $attendee2 = Net::ICal::Attendee->new('davem');
my $attendee3 = Net::ICal::Attendee->new('mini');
my $start     = Net::ICal::Time->new("TZID=US/Pacific:20010329T090000");
my $dur       = Net::ICal::Duration->new("PT2H0M0S");
my $end       = $start->clone->add($dur);

my $event = Net::ICal::Event->new(
				   dtstart	=> $start,
				 # dtend	=> $end,
				   duration	=> $dur,
				   organizer	=> $organizer,
				   attendee	=> [ $attendee2, $attendee3 ],
                                 ) ||
  die "Didn't get a valid ICal object";

my $recur = Net::ICal::Recurrence->new();

$recur->freq('MONTHLY');
$recur->interval(3);
$recur->bymonthday([15, -1]);
$recur->count(5);

$event->rrule([$recur]);

my $cal = Net::ICal::Calendar->new(
				    events => [ $event ],
                                  );

#print $cal->as_ical;

my $vperiod = Net::ICal::Period->new(
                Net::ICal::Time->new('TZID=US/Pacific:20010415T000000'),
	        Net::ICal::Time->new('TZID=US/Pacific:20020811T000000')
	      );
foreach my $occurrence (@{$event->occurrences($vperiod)}) {
  if (ref($occurrence) eq 'Net::ICal::Period') {
    print "OCCURRENCE = ",
	  strftime('%a %x %X - ', localtime($occurrence->start->as_int)),
	  strftime("%X\n",     localtime($occurrence->end->as_int));
    #print "    PERIOD = ", $occurrence->as_ical, "\n";
  } else {
    print "OCCURRENCE = ",
	  strftime("%a %x %X\n", localtime($occurrence->as_int));
  }
}
