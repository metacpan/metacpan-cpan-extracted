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
# $Id: Alarm.pm,v 1.19 2001/07/19 03:32:32 srl Exp $
#
# (C) COPYRIGHT 2000-2001, Reefknot developers.
#
# See the AUTHORS file included in the distribution for a full list.
#======================================================================

=head1 NAME

Net::ICal::Alarm -- represents an alarm (a VALARM object).

=cut

package Net::ICal::Alarm;
use strict;

use base qw(Net::ICal::Component);
use Net::ICal::Trigger;

=head1 SYNOPSIS

  use Net::ICal;

  # simple syntax
  $a = new Net::ICal::Alarm(action => 'DISPLAY',
                            trigger => "20000101T073000",
                            description => "Wake Up!");

  # elaborate
  $a = new Net::ICal::Alarm (action => 'EMAIL',
			     trigger => new Net::ICal::Trigger (
				  type => 'DURATION',
				  content => new Net::ICal::Duration ("-PT5M"),
				  related => 'END
			     ),
			     attendee => [new Net::ICal::Attendee('mailto:alice@wonderland.com')],
			     summary => "mail subject",
			     description => "mail contents");

=head1 DESCRIPTION

This class handles reminders for Net::ICal Events and Todos. You can
get a reminder in several different ways (a sound played, a message
displayed on your screen, an email or a script/application run
for you) at a certain time, either relative to the Event or Todo
the Alarm is part of, or at a fixed date/time.

=head1 CONSTRUCTOR

=head2 new (optionhash)

Create a new Alarm. The minimum options are an action, a trigger and
either an attach or a description.

The action describes what type of Alarm this is going to be. See
L<"action"> below for possible actions. The trigger describes when
the alarm will be triggered. See L<"trigger"> below for an explanation.

=begin testing
use Net::ICal::Alarm;

my $a = Net::ICal::Alarm->new();

ok(!(defined($a)), 'new Alarm with no events should fail');


$a = Net::ICal::Alarm->new( action => 'DISPLAY', 
                            trigger => '-5M',
                            description => 'time for meeting');

ok(defined($a), 'new Alarm with DISPLAY, trigger, and desc is created');

$a = Net::ICal::Alarm->new( action => 'EMAIL', 
                            trigger => '-5M',
                            description => 'time for meeting');

ok(defined($a), 'new Alarm with EMAIL, trigger, and desc is created');

# TODO: we need as_ical tests and such. These tests are only
# barely adequate.

=end testing

=cut

sub new {
    my ($class, %args) = @_;
   
    # this implements the heart of RFC2445 4.6.6, which says what
    # elements in an Alarm are required to be used.
    # Anything that's "return undef" is requred.
    
    # action and trigger are required.
    return undef unless defined $args{'action'};
    return undef unless defined $args{'trigger'};

    # display and email alarms must have descriptions.
    if ($args{'action'} eq 'DISPLAY' or $args{'action'} eq 'EMAIL') {
	return undef unless defined $args{'description'};
    }
    if (($args{'action'} ne 'EMAIL') and (defined $args{'attendee'})) {
        return undef;
    }

    # procedure alarms must invoke an attachment.
    # TODO: Attachments? This could be (is) implemented very poorly in some
    # of MS's software. eek.
    #BUG: 404132
    if ($args{'action'} eq 'PROCEDURE') {
	return undef unless defined $args{'attach'};
    }

    # duration and repeat must be used together or not at all.
    if (defined $args{'duration'} xor defined $args{'repeat'}) {
    	return undef;
    }

    #FIXME: it sucks we have to do this in every component. better
    #       try to get this into Component
    #BUG: 233771
    my $t = $args{'trigger'};
    unless (ref ($t)) {
	$args{'trigger'} = new Net::ICal::Trigger ($t);
    }

    return &_create ($class, %args);
}

#============================================================================
# create ($class, %args)
#
# sets up a map of the properties that N::I::Alarm objects share.
# See Net::ICal::Component and Class::MethodMapper if you want to know
# how this works. Takes a class name and a hash of arguments, returns a new
# Net::ICal::Alarm object. 
#============================================================================
sub _create {
  my ($class, %args) = @_;
   
=head1 METHODS

=head2 action

What the Alarm does when fired.  The default type is EMAIL.

=over 4

=item * AUDIO - play an audio file. Requires an L<"attach"> property
(a soundfile).

=item * DISPLAY - pop up a note on the screen. Requires a L<"description">
containing the text of the note.

=item * EMAIL - send an email. Requires a L<"description"> containing the
email body and one or more L<"attendee">s for the email address(es).

=item * PROCEDURE - trigger a procedure described by an L<"attach">
which is the command to execute (required).

=back

=head2 trigger

The time at which to fire off the reminder. This can either be relative
to the Event/Todo (a L<Net::ICal::Duration> or at a fixed date/time
(a L<Net::ICal::Time>).

=head2 summary

If the Alarm has an EMAIL L<"action">, the text of the summary string
will be the Subject header of the email.

=head2 description

If the Alarm has an EMAIL L<"action">, the text of the description string
will be the body of the email. If the Alarm has a PROCEDURE L<"action">,
this is the argument string to be passed to the program.

=head2 attach

If the Alarm has an AUDIO L<"action">, this contains the sound to be played,
either as an URL or inline. If the Alarm has an EMAIL L<"action">, this
will be attached to the email. If the Alarm has a PROCEDURE L<"action">,
it contains the application to be executed.

=head2 attendee

If the Alarm has an EMAIL L<"action">, this contains one or more
L<Net::ICal::Attendee> objects that describe the email addresses of the
people that need to receive this Alarm.

=head2 repeat

The number of times the Alarm must be repeated. If you specify this,
you must also specify L<"duration">.

=head2 duration

The time before the Alarm is repeated. This is a L<Net::ICal::Duration>
object. If you specify this, you must also specify L<"repeat">.

=cut

   #TODO: validation of the parameters is performed by the new method.
   #      <LotR> actually, validation needs to be consistantly put in
   #      a seperate sub 

   my $map = {		# RFC2445 4.6.6
      action => { # 4.8.6.1
	 type => 'parameter',
	 doc => 'the action type of this alarm',
	 domain => 'enum',
	 options => [qw(AUDIO DISPLAY EMAIL PROCEDURE)],
	 value => 'EMAIL', # default
      },
      trigger => { # 4.8.6.3
	 type => 'parameter',
	 doc => 'when the alarm will be triggered',
	 domain => 'ref',
	 options => 'Net::ICal::Trigger',
	 value => undef,
      },
      description => { # 4.8.1.5
	 type => 'parameter',
	 doc => 'description of this alarm',
	 domain => 'param',
	 options => [qw(altrep language)],
	 value => undef,
      },
    # this might be better off as a class
      attach => { #4.8.1.1
	 type => 'parameter',
	 doc => 'an attachment',
	 domain => 'param',
	 options => [qw(encoding value fmttype)],
	 value => undef,
      },
      summary => { # 4.8.1.12
	 type => 'parameter',
	 doc => 'the summary (subject) if this is an EMAIL alarm',
	 domain => 'param',
	 options => [qw(altrep language)],
	 value => undef,
      },
      attendee => { # 4.8.4.1
	 type => 'parameter',
	 doc => 'the attendees (receivers of the email) for this EMAIL alarm',
	 domain => 'ref',
	 options => 'ARRAY',
	 value => undef,
      },
      duration => { # 4.8.2.5
	 type => 'parameter',
	 doc => 'the delay period between alarm repetitions',
	 value => 0,
      },
      repeat => { # 4.8.6.2
	 type => 'parameter',
	 doc => 'the amount of times the alarm is repeated',
	 value => 0,
      },
   };
   my $self = $class->SUPER::new ('VALARM', $map, %args);

   return $self;
}

1;

=head1 SEE ALSO

More documentation pointers can be found in L<Net::ICal>.

=cut
