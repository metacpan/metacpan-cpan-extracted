#!/usr/bin/perl -w
# vi:sts=4:shiftwidth=4
# -*- Mode: perl -*-
#======================================================================
#
# This package is free software and is provided "as is" without
# express or implied warranty.  It may be used, redistributed and/or
# modified under the same terms as perl itself. ( Either the Artistic
# License or the GPL. )
#
# $Id: Calendar.pm,v 1.19 2001/07/24 02:28:08 srl Exp $
#
# (C) COPYRIGHT 2000-2001, Reefknot developers.
#
# See the AUTHORS file included in the distribution for a full list.
#======================================================================

=head1 NAME

Net::ICal::Calendar -- Hold and manipulate events, todo items and
journal entries.

=cut

package Net::ICal::Calendar;
use strict;

use base qw(Net::ICal::Component);

=head1 SYNOPSIS

  use Net::ICal;

  my $cal = new Net::ICal::Calendar(
  	alarms 	  => [ array of alarm objects ],
   	events 	  => [ array of event objects ],
   	todos 	  => [ array of todo objects ],
   	journals  => [ array of journal objects ],
   	timezones => [ array of timezone objects ],
  );

=head1 TO BE IMPLEMENTED LATER

  # Has the calendar been modified since we last checked?
  if( ! ($cal->last_modified() > $our_last_mod_time)){
    return;
  }

  # Only deal with meeting requests from Larry 
  foreach $message ($cal->messages() ){
    if($message->method() eq 'REQUEST' &&
       $message->type() eq 'VEVENT' &&
       $message->organizer() eq 'mailto:larray@example.com'){

      my @overlaps = $cal->overlap_search($message);

      if($#overlaps){
	# Reject or counterpropose the request
	my $new_time = 
	$cal->next_free_time(Net::ICal::Time(time(0),
					 $message->span()->duration(),
					 $message->span()->priority()));
      } else {
	# Add it to the calendar
	$cal->book($message);
      }
    }

    #Now check for any alarms in the next hour
    @alarms= $cal->alarms(new Net::ICal::Period(time(0),"1h"));

  }


=head1 DESCRIPTION

A Net::ICal::Calendar represents Calendar that can hold events, todo
items, journal entries (and incoming messages?).

=cut

# TODO: what's that about incoming messages? How are we handling those?
# I think we should just handle them in the same data structures with
# messages that we generate, and use the UID to figure out whether we
# generated them or not. --srl

=head1 METHODS

=cut

#=======================================================================

=head2 new()

Construct a new calendar, given sets of data to put in the calendar.
See the example above. 

=begin testing

use Net::ICal::Calendar;
use Net::ICal::Event;

my $c = Net::ICal::Calendar->new();

ok(!(defined($c)), "create fails properly if params are empty");

$c = Net::ICal::Calendar->new (events => [
            Net::ICal::Event->new(dtstart => '20010402T021030Z')
                                ]);

ok(defined($c), 'create passes if at least one event');

=end testing

=cut

#=======================================================================

sub new {
    my ($class, %args) = @_;


   # one of the following has to be defined. 
   return undef unless ( defined $args{'events'}    ||
			 defined $args{'journals'}  ||
   			 defined $args{'todos'}  ||
 		 	 defined $args{'freebusys'} ||
   			 defined $args{'timezones'} );		
    #use Data::Dumper;
    #print Dumper %args;			
    my $self = &_create ($class, %args);

    # set here instead of in the map so we can read in other stuff
    # in new_from_ical and still check for duplicates by testing
    # for undef
    $self->version ('2.0');
    # TODO: find out what we have to do to make sure this is unique.
    $self->prodid ('-//Reefknot Project//NONSGML Net::ICal//EN');

    return $self;
}


# Documentation below swiped from N::I::Component, which this is a child class of. 
#============================================================================

=head2 new_from_ical
   
Creates a new Net::ICal::Calendar from an ical stream.
Use this to read in a new object before you do things with it. 
(Inherited from Net::ICal::Component; read its documentation if you're
curious.)

=cut

#============================================================================
# XXX: this is commented out because right now we're just using the 
# N::I::Component version of this sub. We might want to run new_from_ical items
# through the tests in new(), above, or something, to verify that they're sane
# objects. 
#sub new_from_ical {}


=head1 METHODS FOR INTERNAL USE ONLY

None of the following methods should be relied on by anything outside
this module. Use at your own risk.

=head2 _create ($class, %args)

Sets up a Class::MethodMapper map to describe the data in this class,
then initialize the object. Takes a classname and a hash of arguments,
returns a Net::ICal::Calendar. See the Class::MethodMapper docs if you
want to understand what this does slightly better.

=cut

sub _create {
  my ($class, %args) = @_;

  # See the Class::MethodMapper docs to understand more about what this does.
  # Basically, it sets up a series of accessor functions for various tiny
  # data elements within a calendar. 
  my $map = {

    # the attributes of the calendar as a whole. See RFC2445 4.7
    calscale => {	# RFC2445 4.7.1  - OPTIONAL
	  type => 'parameter',
	  doc => 'what sort of calendar is this (default gregorian)',
	  domain => 'enum',
	  # not sure if we should define these enums; gregorian is default, 
	  # and I'm not sure if others have been defined by IETF. But
	  # this allows us to handle non-Gregorian calendar concepts. 
	  # It might also allow us to define some concept of, say, 
	  # 28-hour-6-day weeks, for those who are into that. ;) --srl
	  options => [qw(GREGORIAN ISLAMIC)],	
	  value => undef,
    },
    
    method => {  	# RFC2445 4.7.2   - OPTIONAL
      # this is a METHOD name as specified in RFC2446 (iTIP). 
	  # it lets you say whether this is a request for a meeting, 
	  # a response to a request, or what. 
	  type => 'parameter',	
	  doc => 'RFC2446 method string',
	  value => undef, 
    },	

    prodid => {	# RFC2445 4.7.3   - REQUIRED, DEFAULT INCLUDED
	  type => 'parameter',
	  doc => 'what product created this iCalendar',
    },	
    
    version => {  	# RFC2445 4.7.4   - REQUIRED, DEFAULT INCLUDED
	  type => 'parameter',
	  doc => 'version of the iCalendar spec this iCal conforms to',
    },	
      
    # things that go 'inside' a calendar object; see RFC2445 4.6
    # there should be at least one of these.
      
    # yes, I know that some of these plurals are strange, but alarm is
    # a reserved perl keyword. bah.  ---srl
    events => {	# RFC 2445 4.6.1  
	  type => 'parameter',
	  doc => 'the events in this calendar',
	  domain => 'ref',
	  options => 'ARRAY',
	  value => undef,
    },
    
    todos => {		# RFC 2445 4.6.2
	  type => 'parameter',
	  doc => 'things to do',
	  domain => 'ref',
	  options => 'ARRAY',
	  value => undef,
    },
    
    journals => {	# RFC 2445 4.6.3
	  type => 'parameter',
	  doc => 'my notes',
	  domain => 'ref',
	  options => 'ARRAY',
	  value => undef,
    },
    
    freebusys => {	# RFC2445 4.6.4
	  type => 'parameter',
	  doc => 'when am i free or busy?',
	  domain => 'ref',
	  options => 'ARRAY',
	  value => undef,
    },
    
    timezones => {	# RFC2445 4.6.5
	  type => 'parameter',
	  doc => 'when am i free or busy?',
	  domain => 'ref',
	  options => 'ARRAY',
	  value => undef,
    },
    
    alarms => {	# RFC2445 4.6.6
	  type => 'parameter',
	  doc => 'warn me when some things happen',
	  domain => 'ref',
	  options => 'ARRAY',
	  value => undef,
    },
 
   };
   
   my $self = $class->SUPER::new ('VCALENDAR', $map, %args);

   return $self;
}

# There was more documentation here at CVS version 1.5, but I've
# deleted it in preparation for the release of Net::ICal 0.13. 
# We can always retrieve it from CVS if we want it back. --srl

1;

=head1 SEE ALSO

More documentation pointers can be found in L<Net::ICal>.

=cut
