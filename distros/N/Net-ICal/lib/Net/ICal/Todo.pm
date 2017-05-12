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
# $Id: Todo.pm,v 1.16 2001/07/09 20:52:57 lotr Exp $
#
# (C) COPYRIGHT 2000-2001, Reefknot developers.
#
# See the AUTHORS file included in the distribution for a full list.
#======================================================================

=head1 NAME

Net::ICal::Todo -- Todo class

=cut

package Net::ICal::Todo;
use strict;

use base qw(Net::ICal::ETJ);

use Net::ICal::Util qw(add_validation_error);
# TODO: work on this documentation.

=head1 SYNOPSIS

  use Net::ICal::Todo;
  my $c = new Net::ICal::Todo();

=begin testing

use Net::ICal::Todo;

=end testing

=head1 DESCRIPTION

Net::ICal::Todo represents something someone needs to get done.   

=head1 BASIC METHODS

=head2 new($args)

Construct a new Todo. Parameters are in a hash.
Meaningful parameters are:

=head2 REQUIRED

=over 4

=item * organizer - a Net::ICal::Attendee for who's organizing this meeting. 

=back

=head2 OPTIONAL

=over 4

=item * dtstart - a Net::ICal::Time for when this Todo starts.

=item * duration - a Net::ICal::Duration; how long this thing will take
to do. 

=item * alarms - an array of Net::ICal::Alarm objects; reminders about
doing this item. 

=item * class - PUBLIC, PRIVATE, or CONFIDENTIAL - the creator's intention
about who should see this Todo.

=item * created - a Net::ICal::Time saying when this object was created.

=item * description - a hash with at least a content key, maybe an altrep 
and a language key. Content is a description of this Todo. 

=item * dtstamp - when this Todo was created. Will be set to the current 
time unless otherwise specified.

=item * geo - a pair of real numbers--- the latitude and longitude of 
this Todo.

=item * last_modified - a Net::ICal::Time specifying the last time this 
object was changed.

=item * location - a hash for where this Todo is taking place. The 
content key points to a string about the location; the altrep key gives 
an alternate representation, for example a URL.

=item * priority - a number from 0 (undefined) to 1 (highest) to 
9 (lowest) representing how important this event is.

=item * status - NEEDS-ACTION, IN-PROGRESS, COMPLETED, or CANCELLED; 
the status of this todo item.

=item * summary - a one-line summary of this Todo. If you need more 
space, use the description parameter.

=item * uid - a globally unique identifier for this event. Will be created
automagically.

=item * url - a URL for this Todo. Optional.

=item * attach - a Net::ICal::Attach - attached file for this Todo. 

=item * attendee - who's going to be at this meeting; an array of 
Net::ICal::Attendee objects.

=item * categories - what categories this event falls into. Make up 
your own categories. Optional.

=item * comment - a hash like that for description (above), comments 
on this Todo item.

=item * contact - a string describing who to contact about this Todo.

=item * request_status - how successful we've been at scheduling this Todo 
so far. Values can be integers separated by periods. 1.x.y is a preliminary 
success, 2.x.y is a complete successful request, 3.x.y is a failed request 
because of bad iCal format, 4.x.y is a calendar server failure. 

=item * related_to - an array of other Event, Todo, or Journal objects this 
Todo is related to. 

=item * resources - resources (such as an overhead projector) required for 
doing this task.

=item * sequence - an integer that starts at 0 when this object is 
created and is incremented every time the object is changed. 

=back

=head2 RECURRING TASKS

=over 4

=item * recurrence_id - if this task occurs multiple times, which occurrence of
it is this particular task?

=item * rdate - an array of Net::ICal::Time objects describing repeated occurrences
of this task. 

=item * rrule - an array of Net::ICal::Recurrence objects telling when
this task repeats. 

=item * exdate - a Net::ICal::Time giving a single-date exception to a 
recurring task.

=item * exrule - an array of  Net::ICal::Recurrence objects giving a 
recurring exception to a recurring task.

=back

=for testing
ok($c = Net::ICal::Todo->new , "Simple creation should return an object");

=cut

sub new {
    my ($class, %args) = @_;

    my $self = &_create ($class, %args);
    return undef unless (defined $self);
    $self->_init;
    return undef unless ($self->validate);

    return $self;
}

=pod

=head2 $class->validate

Validates the properties of a Todo.  Returns 1 for success, undef for
failure.

TODO: make sure that this object has the bare minimum requirements
specified by the RFC.

=for testing
ok( $c->validate , "Simple todo should pass");

=cut

sub validate {
    my ($self) = @_;

    if (defined $self->due and $self->duration) {
	add_validation_error ($self, "Can't have both due and duration in one Todo");
    }
    if ($self->dtstart and $self->due) { # 4.8.2.3
	my $foo = $self->dtstart->compare ($self->due);
	if ($self->dtstart->compare ($self->due) > 0) {
	add_validation_error ($self, "the due time must not be earlier than the dtstart time");
	}
    }
    if ($self->completed and $self->completed !~ /Z$/) { # 4.8.2.1
	add_validation_error ($self, "The completed date/time MUST be a UTC value");
    }

    return $self->SUPER::validate;
}

=pod

=head1 DEVELOPER METHODS

The following methods are probably not of interest to you unless you are
a Reefknot developer.

=head2 $c->_create(%args)

Class::MethodMapper creation routine.

=for testing
#ok($c->_create(%args), "Simple _create call");

=cut

sub _create {
    my ($class, %args) = @_;

    # don't pass in the %args just yet, as we don't have a complete
    # map
    my $self = $class->SUPER::_create ('VTODO');

    # add new elements to the map. 
    my $map = {	
	completed => { # 4.8.2.1
	    type => 'parameter',
	    doc => 'the time this to-do was completed',
	    domain => 'ref',
	    options => 'Net::ICal::Time',
	    value => undef,
	},
	percent_complete => { # RFC2445 4.8.1.8 - optional in a VTODO 
	    type => 'parameter',
	    doc => 'how completed this task is',
	    value => undef, 
	},
	due => { # RFC2445 4.8.2.3 - optional in a VTODO 
	    type => 'parameter',
	    doc => 'when this has to be done',
	    domain => 'ref',
	    options => 'Net::ICal::Time',
	    value => undef, 

	},
    };
    # add the extra map item definitions
    $self->set_map (%$map);
    
    # now fill in the map values
    $self->set (%args);

    return $self;
}

1;

=head1 SEE ALSO

More documentation pointers can be found in L<Net::ICal>.

=cut
