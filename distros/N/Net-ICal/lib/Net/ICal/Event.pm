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
# $Id: Event.pm,v 1.20 2001/08/04 04:59:36 srl Exp $
#
# (C) COPYRIGHT 2000-2001, Reefknot developers.
#
# See the AUTHORS file included in the distribution for a full list.
#======================================================================

=head1 NAME

Net::ICal::Event -- Event class

=cut

package Net::ICal::Event;
use strict;
use Net::ICal::Util qw(:all);

use base qw(Net::ICal::ETJ);

=head1 SYNOPSIS

  use Net::ICal::Event;

  my $e = new Net::ICal::Event (
  	organizer => new Net::ICal::Attendee('alice'),
	uid => 'fooid',
	alarms => [Net::ICal::Event objects],
	dtstart => new Net::ICal::Time("20010207T160000Z"),
	summary => 'tea with the white rabbit',
  );


=head1 DESCRIPTION

Net::ICal::Event represents iCalendar events.  

=pod

=head1 BASIC METHODS

=head2 new($args)

Construct a new Event. Parameters are in a hash.
Meaningful parameters are:


=head2 REQUIRED

=over 4

=item * dtstart - a Net::ICal::Time for when this event starts.

=item * dtend - a Net::ICal::Time for the end of this event. Use either 
this OR a duration (below). Use when the ending time of an event is fixed 
("I have to leave at 3pm to pick up my child.")

=item * duration - a Net::ICal::Duration; how long this event lasts. Use 
for things like plane flights - "The trip will take 2 hours, no matter 
when the plane takes off. If I start late, I end late." Use either 
this OR a dtend, above.

=item * organizer - a Net::ICal::Attendee for who's organizing this meeting. 

=back

=head2 OPTIONAL

=over 4

=item * attendee - who's going to be at this meeting; an array of 
Net::ICal::Attendee objects.

=item * categories - what categories this event falls into. Make up 
your own categories. Optional.

=item * comment - a hash like that for description (above), comments 
on this event.

=item * contact - a string describing who to contact about this event. 

=item * request_status - how successful we've been at scheduling this event 
so far. Values can be integers separated by periods. 1.x.y is a preliminary 
success, 2.x.y is a complete successful request, 3.x.y is a failed request 
because of bad iCal format, 4.x.y is a calendar server failure. 

=item * related_to - an array of other Event, Todo, or Journal objects this 
Event is related to. 

=item * resources - resources (such as an overhead projector) required for 
this event.

=item * sequence - an integer that starts at 0 when this object is 
created and is incremented every time the object is changed. 

=back

=head2 RECURRING EVENTS

=over 4

=item * recurrence_id - if this event occurs multiple times, which occurrence of
it is this particular event?

=item * rdate - an array of Net::ICal::Time objects describing repeated occurrences
of this event. 

=item * rrule - an array of Net::ICal::Recurrence objects telling when
this event repeats. 

=item * exdate - a Net::ICal::Time giving a single-date exception to a 
recurring event.

=item * exrule - an array of  Net::ICal::Recurrence objects giving a 
recurring exception to a recurring event.

=back

=begin testing

use Net::ICal::Event;

my $e = Net::ICal::Event->new();

ok(!(defined($e)), 'new() called with no params should fail');

# FIXME: grah, this should work; DWIM. 
$e = Net::ICal::Event->new(dtstart => '20011031Z');

ok(defined($e), 'new() called with only dtstart(string) should succeed');

$e = Net::ICal::Event->new(dtstart => Net::ICal::Time->new(
                                        ical => '20011031Z')
                            );

ok(defined($e), 'new() called with only dtstart(object) should succeed');


# output this object as ical, then read it back in from ical and test
# to make sure nothing changed. This is the only way I can see to 
# sanely test creation of complex objects. 

my $e_ical = $e->as_ical;
my $e2 = Net::ICal::Event->new_from_ical($e_ical);
ok(defined($e2), "reading in iCal I created succeeds at a basic level");

print "e2 dtstart is " . $e2->dtstart()->as_ical . "\n";
print "e dtstart is " . $e->dtstart()->as_ical . "\n";

ok(($e2->dtstart->as_ical eq $e->dtstart->as_ical), 'iCal output and reimport of simple event works');

=end testing

=cut


sub new {
    my ($class, %args) = @_;

    #TODO: check for args that are specifically required in Events.
    #BUG: 424137

    my $self = &_create ($class, %args);
    $self->_init;

    return undef unless ($self and $self->validate);

    return $self;
}

sub validate {
    my ($self) = @_;

    unless (defined $self->dtstart) {
	    add_validation_error ($self, "You must have a dtstart in an Event");
    }

    if (defined $self->dtend and $self->duration) {
    	add_validation_error ($self, "Can't have both dtend and duration in one Event");
    }

    return $self->SUPER::validate;
}

sub _create {
    my ($class, %args) = @_;

    my $self = $class->SUPER::_create ('VEVENT');

    #TODO: modify the map to include map values that are specific
    #      to Events, if any.
    #BUG: 424139
    my $map = {
	dtend => { # 4.8.2.2
	    type => 'parameter',
	    doc => 'when this event ends',
	    domain => 'ref',
	    options => 'Net::ICal::Time',
	    value => undef,
	},
	transp => { # 4.8.2.7
	    type => 'parameter',
	    doc => 'does this event block out time',
	    domain => 'enum',
	    options => [qw(OPAQUE TRANSPARENT)],
	    value => undef,
	},
    };

    $self->set_map (%$map);
    $self->set (%args);

    return $self;
}

1;

=head1 SEE ALSO

More documentation pointers can be found in L<Net::ICal>.

=cut
