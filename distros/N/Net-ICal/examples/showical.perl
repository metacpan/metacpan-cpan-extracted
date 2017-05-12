#!/usr/bin/perl -w
# -*- Mode: perl -*-
#======================================================================
#
# This package is free software and is provided "as is" without
# express or implied warranty.  It may be used, redistributed and/or
# modified under the same terms as perl itself. ( Either the Artistic
# License or the GPL. )
#
# $Id: showical.perl,v 1.5 2001/05/09 12:07:59 coral Exp $
#
# (C) COPYRIGHT 2000-2001, Reefknot developers.
#
# See the AUTHORS file included in the distribution for a full list.
#======================================================================

# interprets and displays an iCalendar stream

use strict;
use lib '../lib';

use Net::ICal::Component;
use Net::ICal::Attendee;
use Net::ICal::Duration;
use Net::ICal::Event;
use Net::ICal::Time;
use Net::ICal::Calendar;

unless ($ARGV[0]) {
  print "showical.perl: interprets an iCalendar stream.\n";
  print "Please give the name of an iCalendar file to interpret.\n";
  exit;
}

undef $/;
open(FOO, $ARGV[0]) or die "Can't open $ARGV[0]: $!";
my $cal = Net::ICal::Component->new_from_ical (<FOO>);
close FOO;
my $events = $cal->events;

print "EVENTS:\n---\n";
foreach my $evt (@$events) {
   my $altrep = $evt->summary;
   $evt->dtstart and $altrep .= " (" . scalar $evt->dtstart->format('%x %X') . ")\n";
   $evt->location and $altrep .= "location: " . $evt->location->{content} . "\n";
   $evt->organizer and do {
      $altrep .= "organizer: ";
      $altrep .= ($evt->organizer->cn ?
	    $evt->organizer->cn :
	    $evt->organizer->content);
   };
   $altrep .= "\n";
   print $altrep;

   if ($evt->attendee) {
      print "Attendees\n";
      foreach my $attendee (@{$evt->attendee}) {
	 my $addr = $attendee->content;
	 $addr =~ s/mailto://;
	 print "    $addr (", $attendee->partstat, ")\n";
      }
   }
   print "---\n";
}
