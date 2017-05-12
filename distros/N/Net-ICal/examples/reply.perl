#!/usr/bin/perl -w
# -*- Mode: perl -*-
#======================================================================
#
# This package is free software and is provided "as is" without
# express or implied warranty.  It may be used, redistributed and/or
# modified under the same terms as perl itself. ( Either the Artistic
# License or the GPL. )
#
# $Id: reply.perl,v 1.3 2001/05/09 12:06:52 coral Exp $
#
# (C) COPYRIGHT 2000-2001, Reefknot developers.
#
# See the AUTHORS file included in the distribution for a full list.
#======================================================================

# A simple example script to reply to any meeting request and decline
# to attend it. Requires MIME::Tools. 

use strict;
use lib '../lib';

use MIME::Entity;
use MIME::Parser;

use Net::ICal::Component;
use Net::ICal::Calendar;
use Net::ICal::Event;

# change this to the attendee you want to play
my $me = 'mailto:martijn@khazad-dum.copa.nl';

my $parser = new MIME::Parser;
my $entity = $parser->parse (\*STDIN) or die "parse failed\n";
my $caldata;
foreach my $part ($entity->parts) {
   if ($part->mime_type eq 'text/calendar') {
      $caldata = $part->bodyhandle;
      last;
   }
}
die "no text/calendar part\n" unless ($caldata);
my $handle = $caldata->open('r') or die "error opening body: $!";

undef $/; # apparently needed for getlines as well
my $cal = Net::ICal::Component->new_from_ical ($handle->getlines);
$handle->close;
# assume a single event for now
my ($event) = $cal->events->[0];
my $for_me;
foreach my $attendee (@{$event->attendee}) {
   if (lc ($attendee->content) eq $me) {
      $for_me = $attendee;
      last;
   }
}
unless ($for_me) {
   print "Not an event for me\n";
   exit 1;
}
my $reply = $event->clone;
$for_me->partstat ('DECLINED');
$for_me->rsvp('FALSE');
$reply->attendee ([$for_me]);
my $replycal = new Net::ICal::Calendar (
   method => 'REPLY',
   events => [$reply]);
my ($organizer) = $event->organizer->content =~ /mailto:(.*)/ig;
$me =~ s/mailto://;
my $msg = MIME::Entity->build (
   From => $me,
   To => $organizer,
   Subject => 'confirming meeting',
   Type => 'multipart/mixed');
$msg->attach (
   Type => 'text/calendar; method=REPLY',
   Data => $replycal->as_ical);
$msg->print (\*STDOUT);
$msg->send;
