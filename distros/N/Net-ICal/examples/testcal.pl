#!/usr/local/bin/perl -w

# -*- Mode: perl -*-
#======================================================================
#
# This package is free software and is provided "as is" without express
# or implied warranty.  It may be used, redistributed and/or modified
# under the same terms as perl itself. ( Either the Artistic License or the
# GPL. )
#
# $Id: testcal.pl,v 1.2 2001/07/23 15:09:50 lotr Exp $
#
# (C) COPYRIGHT 2000-2001, Reefknot developers.
# 
# See the AUTHORS file included in the distribution for a full list. 
#======================================================================

use strict;

use lib '../lib';

use Net::ICal;

# send email an hour before to remind us of tea.
my $a = new Net::ICal::Alarm (action => 'EMAIL',
                           trigger => "-3600",
			   attendee => [new Net::ICal::Attendee ("mailto:alice\@wonderland.net")],
			   summary => "mail subject: tea with the rabbit",
			   description => "remember to go to tea.");

# pop up an alarm about tea 5 minutes before. 
my $a2 = new Net::ICal::Alarm (action => 'DISPLAY',
                           trigger => "-300",
			   summary => "time for tea.",
			   description => "Meet the White Rabbit for tea.");


# set up the actual teatime. 
my $e = new Net::ICal::Event (organizer => new Net::ICal::Attendee('alice'),
							  alarms => [$a, $a2],
							  dtstart => new Net::ICal::Time("20010207T160000Z"),
							  summary => 'tea with the white rabbit',
);


my $cal = new Net::ICal::Calendar (events => [$e]);
#print $cal->as_ical;

my $events = $cal->events;
use Data::Dumper;
#print Dumper $alarms;

print "\niterating over event alarms:\n";

foreach my $evt (@$events) {
	# show when this event is scheduled. This is a quick and dirty
	# hack, I know we can format dates more elegantly. 
	print "EVENT: " . $evt->summary . " - ";
	
	print scalar $evt->dtstart->as_localtime . ":";

	print "\n";
	
	# We *desperately* need to be able to get an array of what times
	# to trigger events at. I don't want to do math of "what's the
	# start date, and when relative to that do the events run?". 
	# Net::ICal should give me this for free. 
	
	my $alarms = $evt->alarms;
	
	print "alarms in event: \n"; # . Dumper $alarms;	
	foreach my $a (@$alarms)  {
		#print "\n--------------\n";
		#print $a->as_ical;
		#print Dumper $a;
		print "  alarm type " . $a->action . " is at ";

		# the trigger is when to fire an alarm.
		# are these times supposed to be after or before the dtstart?
		# I assume after. --srl
		
		my $trigger = $a->trigger;
		
		# Duration also needs to be able to give me an intelligibly
		# formatted string, so I don't have to do this. 
		# FIXME: doesn't work with Chad's Duration.pm
		#foreach my $key (keys %{$trigger->content}) {
		#	print $key . "=" . $trigger->content->{$key} . ", ";
		#}

		# the math of figuring out when to actually fire these alarms
		# is left as an exercise to the reader. We need to fix this in
		# the modules so the module user doesn't have to do math like that.
		
		print ": ". $a->description->{content} . "\n";
	}
	print "\n";
}


print "\n" . $cal->as_ical;

print "Paste in the output from the script above (or any VCALENDAR with (an)\n"
    . "embedded VALARM(s)). (not actually correct protocol-wise, but hey)\n"
    . "Hit Ctrl-D twice to end input.\n";

undef $/; # slurp mode
$a = Net::ICal::Component->new_from_ical (<STDIN>);

print "\nBelow should be the same (except the order) as what you pasted\n",
$a->as_ical;
