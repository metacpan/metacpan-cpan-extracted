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
# $Id: ETJ.pm,v 1.40 2001/08/04 04:59:36 srl Exp $
#
# (C) COPYRIGHT 2000-2001, Reefknot developers.
#
# See the AUTHORS file included in the distribution for a full list.
#======================================================================

=head1 NAME

Net::ICal::ETJ - iCalendar event, todo and journal entry base class

=head1 SYNOPSIS

  use Net::ICal::ETJ;

  my $c = new Net::ICal::ETJ(%arguments);

=cut

package Net::ICal::ETJ;
use strict;

use base qw(Net::ICal::Component);

use Net::ICal::Duration;
use Net::ICal::Period;
use Net::ICal::Time;
use Net::ICal::Util qw(:all);

# make sure that this object has the bare minimum requirements
# specified by the RFC.

#TODO: according to http://www.imc.org/ietf-calendar/mail-archive/msg02603.html
#      uid isn't required for iCal, just for iTIP. How do we handle this?
#      (Suggestion: make Net::iTIP a child class, and have its new() routine
#      validate UIDs. --srl)
#BUG: 424113

=pod

=head1 DESCRIPTION

Net::ICal::ETJ represents iCalendar events, todo items and
journal entries. It's a base class for N::I::Event, N::I::Todo,
and N::I::Journal. 

Casual users shouldn't ever need to actually make an ETJ object. The
following documentation is for developers only.

=head1 DEVELOPER DOCUMENTATION

=head2 $self->validate

Performs basic validation on a Net::ICal event, todo or journal object.
Returns 1 for success, undef for failure.

Required properties include:

=over 4

=item *

organizer

=back

=for testing
use Net::ICal::ETJ;
use Net::ICal::Attendee;
my $c = new Net::ICal::ETJ;

my $args = { attendee => new Net::ICal::Attendee('mailto:foo@example.com');

ok( $c->validate($args)      , "Validation of simple, correct ETJ");
ok( not($c->validate())      , "ETJ with no organizer should fail");

=cut

sub validate {
    my ($self) = @_;

    #unless (defined $self->organizer) {
    #	push (@{$@}, "Need an organizer");
    #}
    unless (defined $self->uid) {
	    add_validation_error ($self, "Need a uid");
    }
    # 4.8.7.1
    if ($self->created and $self->created->as_ical_value !~ /Z$/) {
	add_validation_error ($self, "The created date/time MUST be a UTC value");
    }
    # 4.8.7.2
    if ($self->dtstamp and $self->dtstamp->as_ical_value !~ /Z$/) {
	add_validation_error ($self, "The dtstamp date/time MUST be a UTC value");
    }
    # 4.8.7.3
    if ($self->last_modified and $self->last_modified->as_ical_value !~ /Z$/) {
	add_validation_error ($self, "The last_modified date/time MUST be a UTC value");
    }

    # ugly hardcoded call because $self->SUPER is ::ETJ, since $self is
    # one of Event, Todo or Journal.
    return Net::ICal::Component::validate ($self);
}


sub _init {
    my ($self) = @_;

    my $time = Net::ICal::Time->new (epoch => time);

    $self->uid (create_uuid ($time));

    # since DTSTAMP is required by the RFC, we'll create it
    # if it's not given to us. 
    unless (defined ($self->dtstamp) ) {
	    $self->dtstamp ($time);
    }
}

=pod

=head2 _create($foo, $class, %args)

Creates the ETJ object map using Class::MethodMapper

=for testing
ok(Net::ICal::ETJ::_create($foo, $class, %args), "Simple call to _create");

=cut

sub _create {
    my ($foo, $class, %args) = @_;

    my $map = {
	alarms => { # RFC 4.6.6 - optional in VEVENT and VTODO.
	    type => 'parameter',
	    doc => 'the alarms related to this event',
	    domain => 'ref',
	    options => 'ARRAY',
	    value => undef,
	},
	class => { # RFC2445 4.8.1.3 - optional 1x in VEVENT, VTODO, VJOURNAL
	    # this is *not* an access control system; this is the intention of
	    # the calendar owner. see the RFC.
	    type => 'parameter',
	    doc => 'who can see this?',
	    domain => 'enum',
	    options => [qw(PUBLIC PRIVATE CONFIDENTIAL)],
	    value => undef,
	},
	created => { # RFC2445 4.8.7.1 - optional 1x in VEVENT, VTODO, VJOURNAL
	    type => 'parameter',
	    doc => 'when was this first created',
	    domain => 'ref',
	    options => 'Net::ICal::Time',
	    value => undef,
	},
	description => { # RFC2445 4.8.1.5 - optional 1x in VEVENT, VTODO,
			 # VJOURNAL, VALARM - can occur more in VJOURNAL
	    type => 'parameter',
	    doc => 'more details about this event',
	    domain => 'param',
	    options => [qw(altrep language)],
	    value => undef,
	},
	#TODO: needs to be in UTC. how to enforce?
	#BUG: 424114
	dtstart => { # RFC2445 4.8.2.4 - optional in VTODO, VFREEBUSY,
		     # VTIMEZONE; required in VEVENT; not specified in
		     # VJOURNAL
	    type => 'parameter',
	    doc => '',
	    domain => 'ref',
	    options => 'Net::ICal::Time',
	    value => undef,
	},
	duration => { # RFC2445 4.8.2.5 - optional in VEVENT or VTODO, 
		      # meaningless in VJOURNAL
	    type => 'parameter',
	    doc => 'how long this task lasts',
	    domain => 'ref',
	    options => 'Net::ICal::Duration',
	    value => undef,
	},
	due => { # RFC2445 4.8.2.3 - optional in a VTODO, used nowhere else
	    type => 'parameter',
	    doc => 'when this TODO item is done',
	    domain => 'ref',
	    options => 'Net::ICal::Time',
	    value => undef,
	},
	#FIXME: must be a float pair (latitude;longitude) where event/todo is
	#BUG: 424115
	geo => { # RFC2445 4.8.1.6 - optional in VEVENT or VTODO. 
	    type => 'parameter',
	    doc => '',
	    value => undef,
	},
	#TODO: needs to be in UTC. how to enforce?
	#BUG: 424116
	#TODO: a server will need to keep track of this automatically. 
	#BUG: 424117
	last_modified => { # RFC2445 4.8.7.3 - optional in VEVENT, VTODO,
			   # and VJOURNAL
	    type => 'parameter',
	    doc => '',
	    domain => 'ref',
	    options => 'Net::ICal::Time',
	    value => undef,
	},
	location => { # RFC2445 4.8.1.7 - optional in VEVENT or VTODO
	    type => 'parameter',
	    doc => '',
	    domain => 'param',
	    options => [qw(altrep language)],
	    value => undef,
	},
	organizer => { # RFC2445 4.8.4.3 - REQUIRED in VEVENT, VTODO,
		       # VJOURNAL, VFREEBUSY
	    type => 'parameter',
	    doc => '',
	    domain => 'ref',
	    options => 'Net::ICal::Attendee',
	    value => undef,
	},
	# 0=undefined; 1=highest priority; 9=lowest priority, but CUAs
	# can use other schemes. See the RFC.
	priority => { # RFC2445 4.8.1.9 - optional in VEVENT or VTODO
	    type => 'parameter',
	    doc => 'How high a priority is this?',
	    value => 0,
	},
	#TODO: this is the date/time this object was created; should we
	#      set it by default if the user doesn't set it? Does this
	#      have to be in UTC?
	#BUG: 424118
	dtstamp => { # RFC2445 4.8.7.2 - REQUIRED in VEVENT, VTODO,
		     # VJOURNAL, VFREEBUSY
	    type => 'parameter',
	    doc => '',
	    domain => 'ref',
	    options => 'Net::ICal::Time',
	    value => undef,
	},
	#FIXME: these differ radically for VEVENT, VTODO, and VJOURNAL. 
	#       we need to override this in subclasses or something.
	#BUG: 424120
	status => { # RFC2445 4.8.1.1 - optional in VEVENT, VTODO, and VJOURNAL.
	    type => 'parameter',
	    doc => 'overall status or confirmation value',
	    domain => 'enum',
	    options => [qw(TENTATIVE CONFIRMED CANCELLED 
			   NEEDS-ACTION IN-PROGRESS COMPLETED CANCELLED
			   DRAFT FINAL CANCELLED)],
	    value => undef,
	},
	summary => { # RFC2445 4.8.1.12 - optional in VEVENT, VTODO,
		     # VJOURNAL, and VALARM.
	    type => 'parameter',
	    doc => 'a one-line summary',
	    options => [qw(altrep language)],
	    value => undef,
	},
	uid => { # RFC2445 4.8.4.7 - REQUIRED in VEVENT, VTODO, VJOURNAL,
		 # VFREEBUSY
	    type => 'parameter',
	    doc => 'global-unique identifier for a generated event',
	    value => undef,
	},
	url => { # RFC2445 4.8.4.6 - optional 1x in VEVENT, VTODO, VJOURNAL,
		 # VFREEBUSY. 
	    type => 'parameter',
	    doc => 'a url associated with this event',
	    value => undef,
	},
	# This keeps track of *which* Monday at 10am meeting
	# this one is. it's used together with UID.
	recurrence_id => { # RFC2445 4.8.4.4 - optional in any recurring
			   # calendar component. 
	    type => 'parameter',
	    doc => 'which occurrence of a recurring event is this?',
	    domain => 'ref',
	    options => 'Net::ICal::Time',
	    value => undef,
	},
	#TODO: there can be one or more of these, and it should be a
	#       N::I::Attach
	#BUG: 424123
	attach => { # RFC2445 4.8.1.1 - optional in VEVENT, VTODO,
		    # VJOURNAL, VALARM
	    type => 'parameter',
	    doc => '',
	    domain => 'ref',
	    options => 'ARRAY',
	    value => undef,
	},
	attendee => { # RFC2445 4.8.4.1 - optional in VEVENT, VTODO, VJOURNAL;
		      # PROHIBITED in VFREEBUSY and VALARM
	    type => 'parameter',
	    doc => 'who is coming to this meeting',
	    domain => 'ref',
	    options => 'ARRAY',
	    value => undef,
	},
	categories => { # RFC2445 4.8.1.2 - optional in VEVENT, VTODO, VJOURNAL 
	    type => 'parameter',
	    doc => 'ref',
	    options => 'ARRAY', # there can be more than one of these, just text
	    value => undef,
	},
	#FIXME: there can be more than one of these in an event/todo/journal. 
	#       do they need to be ordered in an array?
	#BUG: 424124
	comment => { # RFC2445 4.8.1.4 - optional in VEVENT, VTODO, VJOURNAL,
		     # VTIMEZONE, VFREEBUSY
	    type => 'parameter',
	    doc => '',
	    domain => 'param',
	    options => [qw(altrep param)],
	    value => undef,
	},
	# i'm really surprised this isn't an Attendee type. but i guess
	# it makes sense. 
	contact => { # RFC2445 4.8.4.2 - optional in VEVENT, VTODO, VJOURNAL,
		     # VFREEBUSY
	    type => 'parameter',
	    doc => 'who to contact about this event',
	    value => undef,
	},
	exdate => { # RFC2445 4.8.5.1 - optional in any recurring component.
	    type => 'parameter',
	    doc => 'a 1-date exception to a recurrence rule',
	    domain => 'ref',
	    options => 'Net::ICal::Time',
	    value => undef,
	},
	exrule => { # RFC2445 4.8.5.2 - optional in VEVENT, VTODO, VJOURNAL
		    # should be a set of Net::ICal::Recurrence objects
	    type => 'parameter',
	    doc => 'A rule that defines the exceptions to a recurrence rule',
	    domain => 'ref',
	    options => 'ARRAY',
	    value => undef,
	},
	# This is a varying-granularity field; read the RFC.
	# 1.x = preliminary success, pending completion
	# 2.x = request completed successfully, possibly with a fallback.
	# 3.x = request failed, syntax or semantic error in client req format
	# 4.x = scheduling error; some kind of failure in the scheduling system.
	# Values can look like "x.y.z" to give even more granularity.
	#TODO: I think we have to define our own error subcodes. --srl
	#BUG: 424125
	# See the CAP draft section 8 for one possible set.
	request_status => { # RFC2445 4.8.8.2 - optional in VEVENT, VTODO,
			    # VJOURNAL, VFREEBUSY
	    type => 'parameter',
	    doc => 'how successful have we been at scheduling this',
	    value => undef,
	},
	related_to => {	# RFC2445 4.8.4.5 - optional multiple times in
			# VEVENT, VTODO, or VJOURNAL
	    type => 'parameter',
	    doc => ' other events/todos/journals this item relates to',
	    domain => 'ref',
	    options => 'ARRAY',   # could be a hash, i guess. 
		value => undef,
	},
	#TODO: only related to VEVENT or VTODO, not VJOURNAL; should
	#      there be an error generated if someone requests this in a
	#      VJOURNAL?
	#BUG: 424126
	#TODO: is this a Net::ICal::Attendee?
	#BUG: 424127
	resources => { # RFC2445 4.8.1.10 - optional in VEVENT or VTODO 
	    type => 'parameter',
	    doc => '',
	    value => undef,
	},
	# should be a set of N::I::Times, i think.
	rdate => { # RFC2445 4.8.5.3 - optional in VEVENT, VTODO, VJOURNAL, VTIMEZONE 
	    type => 'parameter',
	    doc => 'define a set of dates as part of a recurrence set',
	    domain => 'ref',
	    options => 'ARRAY',
	    value => undef,
	},
	# should be a set of Net::ICal::Recurrence objects
	rrule => { # RFC2445 4.8.5.4 - optional multiple times in recurring
		   # VEVENT, VTODO, VJOURNALs. optional 1x in STANDARD or
		   # DAYLIGHT parts of VTIMEZONE. 
	    type => 'parameter',
	    doc => 'a rule to describe when this event, todo, or journal repeats',
	    domain => 'ref',
	    options => 'ARRAY',
	    value => undef,
	},
	# Whenever DTSTART, DTEND, DUE, RDATE, RRULE, 
	# EXDATE, EXRULE, or STATUS are changed, this has to be incremented.
	# starts at 0 and counts up. 
	#TODO: we should be handling this internally, not letting the user 
	#      manipulate it. 
	sequence => {  # RFC2445 4.8.7.4 - optional in VEVENT, VTODO, VJOURNAL
	    type => 'parameter',
	    doc => 'version number of this event/todo/journal',
	    value => undef,
	}

#TODO: look also at rfc2445 4.2.15, RELTYPE - is that something that should
#      go here?
#BUG: 424133
    }; 
    my $myclass = __PACKAGE__;
    my $self = $myclass->SUPER::new ($class, $map, %args);
    bless $self, $foo;
    return $self;
}

=pod

=head2 $self->occurrences($reqperiod)

Given a period of time, determines occurences of an Event/Todo/Journal
within that period.  Returns an arrayref of... what exactly? 

=for testing
ok( $c->occurences($period)           , "Simple call to occurrences");
ok( $c->occurences($empty)            , "Empty period");
ok( not($c->occurences($bogusperiod)) , "Bogus period");

=cut

sub occurrences ($) {
    my ($self, $reqperiod) = @_;

    # Get this event's dtstart, and bump up req
    #TODO: What do we do if dtstart isn't defined? Should dtstart be required?
    #BUG: 424135
    my $dtstart = $self->dtstart; 

    # Does this event have any recurrence rules?  If not, just throw back this
    # period for now.
    #TODO: add EXRULE, EXDATE, and RDATE support
    my $ar_rrules  = $self->rrule();
    my $ar_exrules = $self->exrule();
    my $dtend      = $self->dtend;
    my $duration   = $self->duration;
    #FIXME -- missing the rest
    if (!$ar_rrules || !@$ar_rrules) {
	my $dstartint = $dtstart->epoch;
	if ($dstartint >= $reqperiod->start->epoch &&
	    $dstartint <= $reqperiod->end->epoch) {
	    return [ Net::ICal::Period->new($dtstart, $duration || $dtend) ];
	} else {
	    return [ ];
	}
    }

    # Naive for now -- just collect up the RRULE stuff and don't do anything
    # to it.
    my @occurrences;
    if (@$ar_rrules) {
	foreach my $rrule (@$ar_rrules) {
	    push(@occurrences, @{$rrule->occurrences($self, $reqperiod)});
	}
    } else {
	#FIXME: Event must currently start within period
    }

    return \@occurrences;
}

1;
__END__

=head1 SEE ALSO

L<Net::ICal::Event>, L<Net::ICal::Todo>, L<Net::ICal::Journal>, and if you
want to understand *how* this module works, read the source. You'll need
to understand how L<Class::MethodMapper> works also.

More documentation pointers can also be found in L<Net::ICal>.

=cut
