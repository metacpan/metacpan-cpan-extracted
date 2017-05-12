#!/usr/local/bin/perl -w

# -*- Mode: perl -*-
#======================================================================
#
# This package is free software and is provided "as is" without express
# or implied warranty.  It may be used, redistributed and/or modified
# under the same terms as perl itself. ( Either the Artistic License or the
# GPL. )
#
# $Id
#
# (C) COPYRIGHT 2000, Reefknot developers, including:
#       Eric Busboom, http://www.softwarestudio.org
#======================================================================

use strict;

use lib '../lib';

use Net::ICal;

# test_todo: a demonstration of how to organize a TODO list with Net::ICal.

my $me = new Net::ICal::Attendee('me');

# I want to be able to make, at the simplest, a hash where the keys are
# times and the values are summaries, then 
# iterate the creation of the Todo objects. That wouldn't
# give us descriptions or alarms, though, if we wanted them.  

my $todos = [ 
	 		new Net::ICal::Todo (organizer => $me,
							 dtstart => new Net::ICal::Time(ical => "20010207T120000Z"),
							 summary => 'get work done',
							 percent_complete => 5,
							 due => new Net::ICal::Time(ical => "20010208T090000Z"),
				),

 			new Net::ICal::Todo (organizer => $me,
							 dtstart => new Net::ICal::Time(ical => "20010207T160000Z"),
							 summary => 'talk to PHB',
				),

			new Net::ICal::Todo (organizer => $me,
							 dtstart => new Net::ICal::Time(ical => "20010207T1630000Z"),
							 summary => 'have a meeting',
				),

			new Net::ICal::Todo (organizer => $me,
							 dtstart => new Net::ICal::Time(ical => "20010207T170000Z"),
							 summary => 'recover from meeting',
							 # FIXME: why doesn't this show up?
							 location => 'corner pub',
				),
			];



my $cal = new Net::ICal::Calendar (todos => $todos);

#use Data::Dumper;
#print Dumper $todos;
#print Dumper $cal;

#print $cal->as_ical;

my $todo_list = $cal->todos;
#use Data::Dumper;
#print Dumper $alarms;

print "\nThings to do:\n";

foreach my $todo (@$todo_list) {
	print " - " . $todo->summary . " - ";
	
	print scalar $todo->dtstart->as_localtime ;

	if (defined $todo->due) {
		print " : DUE: " . scalar $todo->due->as_localtime ;
	}

	print "\n";
	
}


print "\n" . $cal->as_ical;
