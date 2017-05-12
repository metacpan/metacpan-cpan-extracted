#!/usr/bin/perl -w
# -*- Mode: perl -*-
#======================================================================
#
# This package is free software and is provided "as is" without
# express or implied warranty.  It may be used, redistributed and/or
# modified under the same terms as perl itself. ( Either the Artistic
# License or the GPL. )
#
# $Id: cal2fb.pl,v 1.5 2001/07/24 11:43:48 lotr Exp $
#
# (C) COPYRIGHT 2000-2001, Reefknot developers.
#
# See the AUTHORS file included in the distribution for a full list.
#======================================================================

# Demo of how to use freebusys.

use strict;

use lib '../lib';
use IO::File;

use Net::ICal;

sub help {
    my $help = <<EOH;
cal2fb.pl - turns a calendar into a VFREEBUSY

SYNTAX:
   perl cal2fb.pl durstring calfile

where durstring is an iCalendar duration string like 'P30D' and 
calfile is the name of an iCalendar file.

EOH
    print $help;
    exit;
}

# get command-line params
my $durstr  = shift @ARGV || help();  
my $calfile = shift @ARGV || die "Missing calendar file name\n";

# open the iCalendar file
my $calfh = IO::File->new($calfile, 'r') || die "can't open $calfile: $!\n";
my $caldata;
$calfh->read($caldata, -s $calfile);
$calfh->close();

# read the calendar file in to make a Calendar object. 
my $cal = Net::ICal::Calendar->new_from_ical($caldata);

my @busyperiods;
my $now = Net::ICal::Time->new(epoch => time());
my $dur = Net::ICal::Duration->new($durstr);
my $rperiod = Net::ICal::Period->new($now, $now->add($dur));

if (my $ar_events = $cal->events) {
  foreach my $event (@$ar_events) {
    my $status = $event->status || 'BUSY';
    # Ignore cancelled events
    next if $status eq 'CANCELLED';
    my $fbtype = $status eq 'TENTATIVE' ? 'BUSY-TENTATIVE' : 'BUSY';
    foreach my $period (@{$event->occurrences($rperiod)}) {
      next unless ref($period) eq 'Net::ICal::Period';
      my $start = $period->start->timezone('UTC');
      my $end   = $period->end->timezone('UTC');
      # Make sure that we have a period with a fixed start/end
      # rather than one with a period
      $period = Net::ICal::Period->new($period->start, $period->end);
      $period->start->timezone('UTC');
      my $fbitem = Net::ICal::FreebusyItem->new($period);
      $fbitem->fbtype($fbtype);
      push(@busyperiods, $fbitem);
    }
  }
}

my $organizer = Net::ICal::Attendee->new($ENV{USER});
my $dtstamp   = Net::ICal::Time->new(epoch => time(), timezone => 'UTC');

my $fbs = Net::ICal::Freebusy->new(freebusy => \@busyperiods,
                                   organizer => $organizer,
				   dtstamp => $dtstamp,
				   dtstart => $rperiod->start,
				   dtend   => $rperiod->end);
my $fbcal = Net::ICal::Calendar->new(freebusys => [$fbs]);
print $fbcal->as_ical;
