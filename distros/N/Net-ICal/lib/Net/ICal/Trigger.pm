#!/usr/bin/perl -w
# -*- Mode: perl -*-
#======================================================================
#
# This package is free software and is provided "as is" without
# express or implied warranty.  It may be used, redistributed and/or
# modified under the same terms as perl itself. ( Either the Artistic
# License or the GPL. )
#
# $Id: Trigger.pm,v 1.10 2001/06/30 20:42:06 lotr Exp $
#
# (C) COPYRIGHT 2000-2001, Reefknot developers.
#
# See the AUTHORS file included in the distribution for a full list.
#======================================================================

=head1 NAME

Net::ICal::Trigger -- represent the TRIGGER property for VALARMs

=cut

package Net::ICal::Trigger;
use strict;

use base qw(Net::ICal::Property);

use Net::ICal::Duration;
use Net::ICal::Time;

=head1 SYNOPSIS

  use Net::ICal;

  # 5 minutes after the end of the event or to-do
  # DURATION is the default type, so it's optional
  $t = new Net::ICal::Trigger (300);
  $t = new Net::ICal::Trigger (new Net::ICal::Duration ("PT5M"),
			       related => 'END');

  # trigger for 7:30am, Jan 1st 2000
  $t = new Net::ICal::Trigger (new Net::ICal::Time ('20000101T073000'));

=head1 DESCRIPTION

Triggers are time markers, used most commonly for Alarms. They're attached to
Times or Durations. 

=begin testing

use lib './lib';
use Net::ICal;
$duration = Net::ICal::Duration->new ('PT5M');
$datetime = Net::ICal::Time->new (ical => '20000101T073000');

=end testing

=head1 CONSTRUCTORS

=head2 new

=for testing
ok(Net::ICal::Trigger->new (300), "Create from integer number of seconds");
ok(Net::ICal::Trigger->new ($duration), "Create from a Net::ICal::Duration");
ok(Net::ICal::Trigger->new ($datetime), "Create from a Net::ICal::Time");

=cut

sub new {
   my ($class, $content, %args) = @_;

   my $ref = ref ($content);

   unless ($ref) {
      if ($content =~ /^[\+-]?P/) {
	 %args = (content => new Net::ICal::Duration ($content));
      } elsif ($content =~ /T/) {
	 %args = (value   => 'DATE-TIME',
		  content => new Net::ICal::Time (ical => $content));
      } else {
	 # explicitly set everything to default
	 %args = (value   => 'DURATION',
		  related => 'START',
		  content => Net::ICal::Duration->new ($content));
      }
   } elsif ($ref eq 'Net::ICal::Duration') {
      %args = (content => $content);
   } elsif ($ref eq 'Net::ICal::Time') {
      %args = (content => $content,
	       value   => 'DATE-TIME');
   } else {
      warn "Argument $content is not a valid Duration or Time";
      return undef;
   }
   return &_create ($class, %args);
}

sub _create {
   my ($class, %args) = @_;

=head1 METHODS

=head2 value([$value])

Get or set the type of the trigger. Valid options are

=over 4

=item DURATION

=item DATE-TIME

=back

=head2 related ([$related])

Get or set the relation of this alarm to the Event or Todo it is
related to. This is only used for alarms that are related to
an Event or Todo component, and its value must be a Duration.
Valid options are

=over 4

=item START

The Duration is relative to the start of the Event or Todo's Period

=item END

The Duration is relative to the end of the Event or Todo's Period

=back

=cut

   my $map = {
      value => {
	 type => 'parameter',
	 doc => 'the type of trigger',
	 domain => 'enum',
	 options => ['DURATION', 'DATE-TIME'],
      },
      content => {
	 type => 'volatile',
	 doc => 'the value of the trigger',
	 domain => 'reclass',
	 options => { qr/^[^P]+$/ => 'Net::ICal::Time',
		      default => 'Net::ICal::Duration'},
	 value => undef,
      },
      related => {
	 type => 'parameter',
	 doc => 'whether this trigger-duration is related to the start or end of the corresponding event/to-do',
	 domain => 'enum',
	 options => [qw(START END)],
      },
   };

   my $self = $class->SUPER::new ('TRIGGER', $map, %args);
   return $self;
}


1;
__END__

=head1 SEE ALSO

L<Net::ICal::Time>, L<Net::ICal::Duration>, L<Net::ICal::Alarm>.

More information can be found in L<Net::ICal>.

=cut
