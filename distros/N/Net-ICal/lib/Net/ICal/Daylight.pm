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
# $Id: Daylight.pm,v 1.3 2001/08/04 05:43:32 srl Exp $
#
# (C) COPYRIGHT 2000-2001, Reefknot developers.
#
# See the AUTHORS file included in the distribution for a full list.
#======================================================================

=head1 NAME

Net::ICal::Daylight -- class for representing DAYLIGHT timezone sections

=cut

package Net::ICal::Daylight;
use strict;

use base qw(Net::ICal::Standard);

use Carp;
use Net::ICal::Property;
use Net::ICal::Util qw(:all);

=head1 DESCRIPTION

This module represents a DAYLIGHT section in a VTIMEZONE, which
details information about when a particular timezone is on
daylight savings time. It includes information about when the
switch back to standard time happens.

=head1 SYNOPSIS

    # really, look at Timezone.pm for a better usage example;
    # this is totally untested

    my $s = Net::ICal::Daylight->new(
        tzoffsetto => '-0400',
        tzoffsetfrom => '-0500',
        rdate => Net::ICal::Recurrence->new ( ...)
        tzname => 'EDT'
    );

=cut

=head1 METHODS

=head2 new(%args)

Makes a new Daylight object. For permissible parameters, see
Net::ICal::Standard.

=begin testing

TODO: {
    local $TODO = "write tests here";
    ok(0, "write tests here, please");
};

=end testing
=head2 new_from_ical ($text)

Takes iCalendar text as a parameter; returns a Net::ICal::Daylight object. 

=cut

# THIS IS INHERITED FROM Net::ICal::Component

#==================================================================================
# make sure that this object has the bare minimum requirements specified by the RFC

=head1 INTERNAL METHODS ONLY

Use these outside this module at your own peril.

=head2 validate($self)

This routine validates the creation arguments we were given
to make sure that we have all the necessary elements to create
a valid VDAYLIGHT.
=cut

=head2 create($class, %args)

This is an internal function that sets up the object. 
It mainly establishes a Class::MethodMapper data map
and hands off creation of the object to Net::ICal::Component.

=cut
sub _create {
    my ($class, %args) = @_;

    # ugh. I hate to replicate this whole thing just for the
    # one line of difference at the end of the sub. 
    # I know there's a better way to do this. Patches welcome.

    my $map = {   # RFC2445 4.6.5 describes VTIMEZONE
        dtstart => {    # RFC2445 4.6.5? - optional in VTIMEZONE,
	        type => 'parameter',
	        doc => '',
	        domain => 'ref',
	        # TODO, BUG 424114: needs to be in UTC. how to enforce?
	        options => 'Net::ICal::Time',
	        value => undef,
   	    },
        tzoffsetto => {	# RFC2445 4.8.3.4 - optional in VTIMEZONE
	        type => 'parameter',
	        doc => 'UTC offset in use now in this timezone',
	        domain => 'param',
	        options => [],
	        value => undef,
   	    },
        tzoffsetfrom => {	# RFC2445 4.8.3.3 - optional in VTIMEZONE
	        type => 'parameter',
	        doc => 'UTC offset in use prior to the current offset in this tz',
	        domain => 'param',
	        options => [],
	        value => undef,
   	    },
   	    rdate => {	# RFC2445 ? - optional multiple times in VTIMEZONE
	        # TODO: this should point to another N::I data type
            type => 'parameter',
	        doc => 'recurrence date',
	        domain => 'ref',
	        options => 'ARRAY',
	        value => undef,
   	    },
   	    rrule => {	# RFC2445 ? - optional multiple times in VTIMEZONE
	        # TODO: this should point to another N::I data type
	        type => 'parameter',
	        doc => 'a recurrence rule',
	        domain => 'ref',
	        options => 'ARRAY',
	        value => undef,
   	    },
   	    tzname => {	# RFC2445 4.8.3.2 - optional multiple times in VTIMEZONE
	        type => 'parameter',
	        doc => 'a name for this timezone',
	        domain => 'param',
	        options => [],
	        value => undef,
   	    },
        # FIXME: handle x-properties. 
    };
    
    # NOTE NOTE NOTE: the following line is the only
    # substantial difference between Daylight and Standard.
    # We do want to refactor this. Patches welcome.
    my $self = Net::ICal::Component->new ('DAYLIGHT', $map, %args);

    return $self;
}

1;

=head1 SEE ALSO

More documentation pointers can be found in L<Net::ICal::Timezone>
and L<Net::ICal::Standard>.

=cut
