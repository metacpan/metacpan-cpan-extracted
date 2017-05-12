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
# $Id: Standard.pm,v 1.4 2001/08/04 05:43:32 srl Exp $
#
# (C) COPYRIGHT 2000-2001, Reefknot developers.
#
# See the AUTHORS file included in the distribution for a full list.
#======================================================================

=head1 NAME

Net::ICal::Standard -- class for representing STANDARD timezone sections

=cut

package Net::ICal::Standard;
use strict;

use base qw(Net::ICal::Component);

use Carp;
use Net::ICal::Property;
use Net::ICal::Util qw(:all);

=head1 DESCRIPTION

This module represents a STANDARD section in a VTIMEZONE, which 
details information about when a particular timezone is on
"standard" (not daylight-savings) time. 

=head1 SYNOPSIS

    # really, look at Timezone.pm for a better usage example;
    # this is totally untested

    my $s = Net::ICal::Standard->new(
        tzoffsetto => '-0500',
        tzoffsetfrom => '-0400',
        rdate => Net::ICal::Recurrence->new ( ...)
        tzname => 'EST'
    );
=cut

=head1 METHODS

=head2 new(%args)

Makes a new Standard object. Permissible arguments are:

=over 4

=item * tzoffsetto - the UTC offset this timezone's in now 

=item * tzoffsetfrom - the UTC offset this timezone was in before it changed

=item * rdate - a recurrence date to describe when this timezone will switch times again

=item * rrule - a recurrence rule to describe when this timezone shifts clocks again

=item * tzname - a human-readable name for this timezone. 

=back

See RFC2445 4.6.5 for more details on how this all works.

=begin testing
TODO: {
    local $TODO = "write tests for N::I::Standard";
    ok(0, "write tests here, please");

};
=end testing
=cut
#============================================================================
sub new {
    my ($class, %args) = @_;

    my $self = &_create ($class, %args);

    return undef unless (defined $self);

    return undef unless ($self->validate);

    return $self;
}

#=================================================================================
=head2 new_from_ical ($text)

Takes iCalendar text as a parameter; returns a Net::ICal::Standard object. 

=cut

# THIS IS INHERITED FROM Net::ICal::Component

#==================================================================================
# make sure that this object has the bare minimum requirements specified by the RFC

=head1 INTERNAL METHODS ONLY

Use these outside this module at your own peril.

=head2 validate($self)

This routine validates the creation arguments we were given
to make sure that we have all the necessary elements to create
a valid VSTANDARD.
=cut
sub validate {
    my ($self) = @_;
	
    # TODO: fill in validation here
   
    return $self->SUPER::validate ($self);
}

=head2 create($class, %args)

This is an internal function that sets up the object. 
It mainly establishes a Class::MethodMapper data map
and hands off creation of the object to Net::ICal::Component.

=cut
sub _create {
    my ($class, %args) = @_;

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

    my $self = $class->SUPER::new ('STANDARD', $map, %args);

    return $self;
}

1;

=head1 SEE ALSO

More documentation pointers can be found in L<Net::ICal::Timezone>.

=cut
