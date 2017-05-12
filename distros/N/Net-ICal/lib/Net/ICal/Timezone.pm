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
# $Id: Timezone.pm,v 1.4 2001/08/04 05:43:32 srl Exp $
#
# (C) COPYRIGHT 2000-2001, Reefknot developers.
#
# See the AUTHORS file included in the distribution for a full list.
#======================================================================

=head1 NAME

Net::ICal::Timezone -- class for representing VTIMEZONEs

=cut

package Net::ICal::Timezone;
use strict;

use base qw(Net::ICal::Component);

use Carp;
use Net::ICal::Property;
use Net::ICal::Util qw(:all);

=head1 DESCRIPTION

This module represents VTIMEZONEs, which detail important information
about timezones. For any timezone, you need to know some important
factors related to it, namely:

=over 4

=item * What UTC offset it's in now ('8 hours before GMT')

=item * What UTC offset it'll be in at the next daylight/standard time shift

=item * When the shifts to and from daylight savings time take place

=back

This object represents those concepts with arrays of Net::ICal::Standard and
Net::ICal::Daylight objects. For more detail on why, see RFC2445 4.6.5. 

If you want some real data to test this module against, see
http://primates.ximian.com/~damon/icalendar/zoneinfo.tgz , which
is a set of VTIMEZONE files that aims to describe every timezone 
in the world. We'll be relying on those files in a future release
as a master timezone database.  They're a translation of the Olsen
timezone database found on Unix systems. 

=head1 SYNOPSIS

    use Net::ICal::Timezone;

    # we know this works
    my $tz = Net::ICal::Timezone->new_from_ical($ical_text);
    
    # we haven't tested this yet, patches welcome
    my $tz = Net::ICal::Timezone->new(
        tzid => 'America/New_York',
        standards => [
            (Net::ICal::Standard objects)                    
        ],
        daylights => [
            (Net::ICal::Daylight objects)
        ]
        );
=cut

=head1 METHODS

=head2 new(%args)

Makes a new Timezone object. Permissible arguments are:

=over 4

=item * tzid - a unique identifier for this timezone

=item * lastmod - the last date/time this timezone info was updated

=item * tzurl - an URL where you can find a newer version of this infi

=item * standards - an array of Net::ICal::Timezone::Standard objects.

=item * daylights - an array of N::I::Timezone::Daylight objects.

=back

=begin testing
TODO: {
    local $TODO = "write tests for N::I::Timezone";
    ok(0, "TODO: write tests for this module");

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

Takes iCalendar text as a parameter; returns a Net::ICal::Timezone object. 

=cut

# THIS IS INHERITED FROM Net::ICal::Component

#==================================================================================
# make sure that this object has the bare minimum requirements specified by the RFC

=head1 INTERNAL METHODS ONLY

Use these outside this module at your own peril.

=head2 validate($self)

This routine validates the creation arguments we were given
to make sure that we have all the necessary elements to create
a valid VTIMEZONE.
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
        tzid => { 	# RFC2445 4.8.3.1 - REQUIRED, only once
            type => 'parameter',
    	    doc => 'unique identifier for this timezone',
 	        domain => 'param',
	        value => undef,
            options => [],
        },
        lastmod => {  	# RFC2445 ? - optional, 1x only in VTIMEZONE
  	        type => 'parameter',
    	    doc => 'last time this item was modified',
	        domain => 'param',
            value => undef,
            options => [],
        },
        tzurl => {  	# RFC2445 4.8.3.5 - optional, 1x only in VTIMEZONE
  	        type => 'parameter',
	        doc => 'a URL for finding the latest version of this VTIMEZONE',
    	    domain => 'param',
            value => undef,
            options => [],
        },
        standards => {	# RFC2445 4.6.5 - required >=1x in VTIMEZONE
	        type => 'parameter',
	        doc => 'a set of standard timezone info',
	        value => undef,
            domain => 'ref',
            options => 'ARRAY',
   	    },
        daylights => {	# RFC2445 4.6.5 - required >=1x in VTIMEZONE
	        type => 'parameter',
	        doc => 'a set of daylight timezone info',
	        value => undef,
            domain => 'ref',
            options => 'ARRAY',
   	    },
        dtstart => {    # RFC2445 4.6.5? - optional in VTIMEZONE,
	        type => 'parameter',
	        doc => '',
	        domain => 'ref',
	        # TODO, BUG 424114: needs to be in UTC. how to enforce?
	        options => 'Net::ICal::Time',
	        value => undef,
   	    },
   	    comment => {	# RFC2445 ? - optional multiple times in VTIMEZONE
	        type => 'parameter',
    	    doc => 'comment about this timezone',
	        domain => 'param',
            options => [],
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

    my $self = $class->SUPER::new ('VTIMEZONE', $map, %args);

    return $self;
}

1;

=head1 SEE ALSO

More documentation pointers can be found in L<Net::ICal>.

=cut
