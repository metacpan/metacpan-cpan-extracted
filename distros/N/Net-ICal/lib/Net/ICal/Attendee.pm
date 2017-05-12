#!/usr/bin/perl -w
# -*- Mode: perl -*-
#======================================================================
#
# This package is free software and is provided "as is" without express
# or implied warranty.  It may be used, redistributed and/or modified
# under the same terms as perl itself. ( Either the Artistic License or the
# GPL. ) 
#
# $Id: Attendee.pm,v 1.20 2001/08/04 04:59:36 srl Exp $
#
# (C) COPYRIGHT 2000, Reefknot developers, including: 
#   Eric Busboom, http://www.softwarestudio.org
# 
# See the AUTHORS file included in the distribution for a full list. 
#======================================================================

=head1 NAME

Net::ICal::Attendee -- represents an attendee or organizer of a meeting

=cut

package Net::ICal::Attendee;
use strict;
use Net::ICal::Util qw(:all);

use UNIVERSAL;
use base qw(Net::ICal::Property);

=head1 SYNOPSIS

  use Net::ICal;
  $a = new Net::ICal::Attendee('mailto:alice@example.com');
  $a = new Net::ICal::Attendee('mailto:alice@example.com',
				cn => 'Alice Anders',
                role => 'REQ-PARTICIPANT');

=head1 DESCRIPTION

Net::ICal::Attendee provides an interface to manipulate attendee data
in iCalendar (RFC2445) format.

=head1 METHODS 

=head2 new($calid, $hash)

New will take a string and optional key-value pairs. The string is the
calender user address of the Attendee (usually a mailto uri).

    $a = new Net::ICal::Attendee('mailto:alice@example.com');
    $a = new Net::ICal::Attendee('mailto:alice@example.com',
                                  cn => 'Alice Anders',
                                  role => 'REQ-PARTICIPANT');

Meaningful hash keys are:


=over 4

=item * cn - common name - the name most people use for this attendee.

=item * cutype - type of user this attendee represents. Meaningful
values are INDIVIDUAL, GROUP, ROOM, RESOURCE, UNKNOWN.

=item * delegated_from - the user who delegated a meeting request to this
attendee.

=item * delegated_to - the user who's been delegated to handle meeting
requests for this attendee.

=item * dir - a URI that gives a directory entry associated with the user.

=item * partstat - whether this attendee will actually be at a meeting.
Meaningful values are NEEDS-ACTION, ACCEPTED, DECLINED, TENTATIVE, 
DELEGATED, COMPLETED, or IN-PROCESS. 

=item * role - how this attendee will participate in a meeting.
Meaningful values are REQ-PARTICIPANT, OPT-PARTICIPANT, NON-PARTICIPANT,
and CHAIR.

=item * rsvp - should the user send back a response to this request?
Valid values are TRUE and FALSE. FALSE is the default. 

=item * sent_by - specifies a user who is acting on behalf of this
attendee; for example, a secretary for his/her boss, or a parent for his/her
10-year-old.

=back

To understand more about the uses for each of these properties,
read the source for this module and and look at RFC2445. 

=begin testing
#generic stuff
use lib "./lib";
use Net::ICal::Attendee;
$mail = 'mailto:alice@example.com';


#start of tests
ok(my $a = Net::ICal::Attendee->new ($mail), "Simple attendee creation");
ok(not(Net::ICal::Attendee->new ("xyzzy")), "Nonsense email address");

=end testing
=cut

sub new {
   my ($class, $value, %args) = @_;
  
   $args{content} = $value;

   #TODO: rsvp should default to false; see rfc2445 4.2.17 and SF bug 424101

   my $self = _create ($class, %args);

   return undef unless $self;

   return undef unless $self->validate;
   
   return $self;
}

=pod

=head2 validate

Returns 1 for valid attendee data, undef for invalid.

=for testing
ok($a->validate, "Simple validation");

=cut

sub validate {
    my ($self) = @_;

    # TODO: write this routine! SF bug 435998

    unless ($self->content =~ /^mailto:.*\@/i) {
        # TODO: make this work
        #add_validation_error($self, "Attendee must begin with 'mailto:'");
        return undef;
    }

    return 1;
}

sub _create {
   my ($class, %args) = @_;

  my $map = {	
    content => {   	    # RFC2445 4.8.4.1
	  type =>'volatile',
	  doc => 'the email address of this attendee',
	  value => undef,
    },
    cn => {			# RFC2445 4.2.2
	  type => 'parameter',
	  doc => "'Common Name', the name most people use to address the user",
	  value => undef,
    },
    cutype => {		# RFC2445 4.2.3
	  type => 'parameter',
	  doc => 'type of user this calid represents',
	  domain => 'enum',
	  options => [qw(INDIVIDUAL GROUP ROOM RESOURCE UNKNOWN)],
	  # This attendee may be a person, or it may be a group, or a place,
	  # or a resource (overhead projector, for example) or something else.
	  value => undef,
    },
    delegated_from => {	# RFC2445 4.2.4
	  type => 'parameter',
	  doc => 'the user this request was delegated from',
	  value => undef,
	  # Someone's passing the buck to Attendee.
    },
    delegated_to => {		# RFC2445 4.2.5
	  type => 'parameter',
	  doc => 'who Attendee is delegating this request to',
	  value => undef,
	  # Mmm, passing the buck to someone else. 
    },
    dir => {			# RFC2445 4.2.6
	  type => 'parameter',
	  doc => 'Directory entry associated with the user',
	  value => undef,
    },
    partstat => {		# RFC2445 4.2.12
	  type => 'parameter',
	  doc => 'status of user-participation',
	  domain => 'enum',
	  options => [qw(NEEDS-ACTION ACCEPTED DECLINED TENTATIVE DELEGATED COMPLETED IN-PROCESS)],
	  value => undef,
	  # whether the user's actually going to be there.  
    },
    role => {			# RFC2445 4.2.16
	  type => 'parameter',
	  doc => 'how the user will participate in the meeting',
	  domain => 'enum',
	  options => [qw(REQ-PARTICIPANT OPT-PARTICIPANT NON-PARTICIPANT CHAIR)],
	  # is the Attendee required, requested, not-participating, or running
	  # the event?
	  value => undef,
    },
    rsvp => {			# RFC2445 4.2.17
	  type => 'parameter',
	  doc => 'User needs to send back a reply to this',
	  domain => 'enum',
	  options => [qw(FALSE TRUE)],
	  value => undef,
    },
    sent_by => {		# RFC2445 4.2.18
	  type => 'parameter',
	  doc => 'who responds on behalf of this Attendee',
	  # a secretary, for example.
	  value => undef,
    },
 };

   return $class->SUPER::new ('ATTENDEE', $map, %args);
}

1;

=head1 SEE ALSO

More documentation pointers can be found in L<Net::ICal>.

=cut
