#!/usr/bin/perl -w
# -*- Mode: perl -*-
#======================================================================
#
# This package is free software and is provided "as is" without
# express or implied warranty.  It may be used, redistributed and/or
# modified under the same terms as perl itself. ( Either the Artistic
# License or the GPL. )
#
# $Id: html_calendar.pl,v 1.3 2001/07/23 15:09:50 lotr Exp $
#
# (C) COPYRIGHT 2000-2001, Reefknot developers.
#
# See the AUTHORS file included in the distribution for a full list.
#======================================================================

use strict;
use lib '../lib';

use Carp;
use CGI qw(:standard);
use HTML::CalendarMonthSimple;

use Net::ICal;

my $DEBUG = 1;

my $cgi = CGI->new();
my $ical = new_default_calendar();

# rkserver.pl - a sample HTML calendar server
#
# possible actions: 
# list  - show the iCal version of the calendar
# send  - allow HTTP upload of a calendar (TODO)
# (default) - show calendar in HTML

if ($cgi->param("action")) {
	if ($cgi->param("action") eq "list") {

		# the user wants a list of current event items
		display_ical_todo_list($cgi, $ical);

	} elsif ($cgi->param("action") eq "send") {
		# TODO: slurp up iCal that was sent by the user

	}

} else { # if no params given
	display_html_calendar($cgi, $ical);

}

#===========================================================================
# SUBROUTINES
#===========================================================================

# show an ical calendar in html.

sub display_html_calendar {
	my ($cgi, $ical) = @_;
	my $events = $ical->events;
	my $todos = $ical->todos;

	# LotR provided the seed code for this. LotR++
	my ($cal, $year, $month);
	
	# display events
	# FIXME: this won't work for events in more than one month, will it?
	foreach my $evt (@$events) {
	   	unless (defined $month) {
      	($year, $month) = ($evt->dtstart->{YEAR} + 1900, $evt->dtstart->{MONTH} + 1);
      	$cal = new HTML::CalendarMonthSimple (year => $year, month => $month);
	   	}
   		if (($evt->dtstart->{YEAR} + 1900 == $year)
	   	and ($evt->dtstart->{MONTH} + 1 == $month)) {
    	  	my $time = "(" . $evt->dtstart->{HOUR} .
         	        ":" . $evt->dtstart->{MINUTE} . ") ";

      		$cal->setcontent (int ($evt->dtstart->{DAY}), $time . $evt->summary);
	   	}
	}
	
	# display todo start and end dates. 
	foreach my $todo (@$todos) {
   		if (($todo->dtstart->{YEAR} + 1900 == $year)
	   	and ($todo->dtstart->{MONTH} + 1 == $month)) {
    	  	my $time = "(" . $todo->dtstart->{HOUR} .
         	        ":" . $todo->dtstart->{MINUTE} . ") ";

      		$cal->setcontent (int ($todo->dtstart->{DAY}), 
				$time . $todo->summary . ' STARTS');
      		
			$cal->setcontent (int ($todo->due->{DAY}), 
				$time . $todo->summary . ' DUE') if ($todo->due);
		}
	}

	print header, start_html ('test'),
      	h1('HTML::CalendarMonthSimple test'), "\n";
	print $cal->as_HTML;
	print "<p><a href=rkserver.pl?action=list>View this calendar in iCal</a>";
	print end_html;

}

sub display_ical_todo_list {
	my ($cgi, $cal) = @_;

	print $cgi->header(-type=>"text/calendar");
	print $cal->as_ical;	

}


# read in a calendar.
sub new_calendar_from_file {
        my ($filename) = @_;
 
        open CALFILE, "<$filename" or (carp $! and return undef);
 
        undef $/; # slurp mode
        # FIXME: this is currently returning "not a valid ical stream"
        # from data saved out by the program itself.
        my $cal = Net::ICal::Component->new_from_ical (<CALFILE>) ;
        close CALFILE;
 
        print "Loaded calendar from $filename\n" if ($DEBUG eq 1 and $cal);
 
        return $cal;
}

# return a default iCal calendar setup.
sub new_default_calendar {
 
        my $me = new Net::ICal::Attendee('me');
 
 
        my $todos = [
                        new Net::ICal::Todo (organizer => $me,
                                                         dtstart => new Net::ICal::Time("20010407T120000Z"),
                                                         summary => 'get work done',
                                                         percent_complete => 5,
                                                         due => new Net::ICal::Time("20010408T090000Z"),
                                ),
 
                        new Net::ICal::Todo (organizer => $me,
                                                         dtstart => new Net::ICal::Time("20010420T160000Z"),
                                                         summary => 'talk to PHB',
                                ),
 
                        new Net::ICal::Todo (organizer => $me,
                                                         dtstart => new Net::ICal::Time("20010415T1630000Z"),
                                                         summary => 'have a meeting',
                                ),
 
                        new Net::ICal::Todo (organizer => $me,
                                                         dtstart => new Net::ICal::Time("20010416T170000Z"),
                                                         summary => 'recover from meeting',
                                                         location => {content => 'corner pub'},
                                ),
                ];
 

	my $events = [
   		new Net::ICal::Event (
      		organizer => new Net::ICal::Attendee ('alice'),
		    dtstart => new Net::ICal::Time ("20010407T160000Z"),
      		summary => 'tea with the white rabbit',
   		),
   		new Net::ICal::Event (
	        organizer => new Net::ICal::Attendee ('alice'),
      		dtstart => new Net::ICal::Time ("20010424T120000Z"),
      		summary => 'lunch with the white rabbit',
   		)
	];


    my $cal = new Net::ICal::Calendar (todos => $todos, events => $events);
    print "Used default calendar\n" if $DEBUG eq 1;
    return $cal;
 
}
