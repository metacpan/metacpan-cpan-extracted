#!/usr/local/bin/perl -w

# This is just a simple demo of how to use Net::ICal::Alarm. 
# Nothing fancy to see here, move along. 

use strict;
use lib '../lib';
use Net::ICal;

$a = new Net::ICal::Alarm (action => 'EMAIL',
                           trigger => "300",
                           #trigger => "19970317T133000Z",
                           #trigger => new Net::ICal::Trigger ("19970317T133000Z"),
                           #trigger => new Net::ICal::Trigger (
			   #   new Net::ICal::Duration ("-PT5M"),
			   #   related => 'END'),
			   attendee => [new Net::ICal::Attendee ("mailto:alice\@wonderland.net")],
			   summary => "mail subject.",
			   description => "mail content.");

print $a->as_ical;
# to see if the normal C::MM stuff still works
#$a->save_config ('test.foo');

#$b = Net::ICal::Alarm->_create;
#$b->restore_config ('test.foo');
#print $b->as_ical;

print "paste in the output from above (or any valid VALARM), then hid Ctrl-D\n";

undef $/; # slurp mode
$a = Net::ICal::Component->new_from_ical (<STDIN>);

print "below should be the same (except the order) as what you pasted\n",
      $a->as_ical;
