#!/usr/bin/perl -w
# -*- Mode: perl -*-
#======================================================================
#
# This package is free software and is provided "as is" without
# express or implied warranty.  It may be used, redistributed and/or
# modified under the same terms as perl itself. ( Either the Artistic
# License or the GPL. )
#
# $Id: FreebusyItem.pm,v 1.8 2001/08/04 04:59:36 srl Exp $
#
# (C) COPYRIGHT 2000-2001, Reefknot developers.
#
# See the AUTHORS file included in the distribution for a full list.
#======================================================================

=head1 NAME

Net::ICal::FreebusyItem -- represents the FREEBUSY property for
VFREEBUSY objects.

=cut

package Net::ICal::FreebusyItem;
use strict;

use base qw(Net::ICal::Property);

use Net::ICal::Duration;
use Net::ICal::Time;

=head1 SYNOPSIS

  use Net::ICal;

  my $p1 = Net::ICal::Period->new("19970101T120000","19970101T123000");
  my $p2 = Net::ICal::Period->new("19970101T133000","19970101T140000");

  my $item1 = Net::ICal::FreebusyItem->new($p1, (fbtype => 'BUSY'));
  my $item2 = Net::ICal::FreebusyItem->new($p2, (fbtype => 'BUSY'));

  # TODO: we ought to be able to do things like:
    my $item3 = Net::ICal::FreebusyItem->new([$p1, $p2], (fbtype => 'BUSY'));
  # so that both items show up on the same line. 

=head1 DESCRIPTION

FreebusyItems are used to mark sections of time that are free to
be scheduled or that are already busy.

=head1 CONSTRUCTORS

=head2 new ($period, %options)

$period is a Net::ICal::Period object. In the future, this
will change to be an array of Periods. Valid keys for the options
hash are:

=over 4

=item * fbtype - can be BUSY, FREE, BUSY-UNAVAILABLE, or BUSY-TENTATIVE;
defaults to BUSY.
BUSY means there's already something scheduled in this time slot. FREE
means that this time slot is open. BUSY-UNAVAILABLE means that this 
time slot can't be scheduled. BUSY-TENTATIVE means that this time slot
has something tentatively scheduled for it. 

=back

=begin testing

use Net::ICal::FreebusyItem;
use Net::ICal::Period;

my $p1 = Net::ICal::Period->new("19970101T120000","19970101T123000");
my $p2 = Net::ICal::Period->new("19970101T133000","19970101T140000");

my $item1 = Net::ICal::FreebusyItem->new();   # should fail
ok(!defined($item1), 'new FreebusyItem without args should fail');

$item1 = Net::ICal::FreebusyItem->new($p1, (fbtype => 'BUSY'));
my $item2 = Net::ICal::FreebusyItem->new($p2, (fbtype => 'BUSY'));

ok(defined($item1), "creation of basic freebusyitem works");

my $item1_ical = $item1->as_ical;

ok(defined ($item1_ical), 'as_ical produces a defined result');

$item1a = Net::ICal::FreebusyItem->new_from_ical($item1_ical);

ok(defined($item1a), 
    "exporting ical and reading it back in creates a defined object");

ok($item1->as_ical eq $item1a->as_ical, 
    "exporting ical and reading it back in creates an identical object");
    
TODO: {
    # TODO: we ought to be able to do things like:
    my $item3 = Net::ICal::FreebusyItem->new([$p1, $p2], (fbtype => 'BUSY'));
    # so that both items show up on the same line. 
    
    local $TODO = 'allow freebusy items to be created with arrays of periods';
    ok(defined($item3), "freebusy items can be created with arrays of periods");

};

=end testing

=cut

sub new {
  my ($class, $content, %args) = @_;

  my $ref = ref ($content);
  return undef unless %args;

  unless ($ref) {
    if ($content =~ /^[\+-]?P/) {
      %args = (content => new Net::ICal::Period ($content));
    } else {
      # explicitly set everything to default
      %args = (content => Net::ICal::Period->new ($content));
    }
  } elsif ($ref eq 'Net::ICal::Period') {
    %args = (content => $content);
  } elsif ($ref eq 'ARRAY') {
    # FIXME: support arrays of periods so that multiple periods can
    # be on one FREEBUSY line separated by commas, as required by the RFC.
    warn "Arrays of Periods aren't yet supported";
    return undef;

  } else {
    warn "Argument $content is not a valid Period";
    return undef;
  }

  # set up the default fbtype
  $args{fbtype} = 'BUSY' unless $args{fbtype};

  return &_create ($class, %args);
}

sub _create {
  my ($class, %args) = @_;

  my $map = {
    fbtype => {     # RFC2445 4.2.9
      type => 'parameter',
      doc => '',
      domain => 'enum',
      options => [qw(FREE BUSY BUSY-UNAVAILABLE BUSY-TENTATIVE)],
      # "The value FREE indicates that the time interval is free for scheduling.
      # The value BUSY indicates that the time interval is busy because one
      # or more events have been scheduled for that interval. The value
      # BUSY-UNAVAILABLE indicates that the time interval is busy and that
      # the interval can not be scheduled. The value BUSY-TENTATIVE indicates
      # that the time interval is busy because one or more events have been
      # tentatively scheduled for that interval. If not specified on a
      # property that allows this parameter, the default is BUSY." -- RFC2445
    
      # FIXME this is actually a property that goes on the same line as a FREEBUSY. 
    },
    content => {
	  type => 'volatile',
	  doc => 'the value of the trigger',
	  domain => 'reclass',
	  options => {default => 'Net::ICal::Period'},
	  value => undef,
    },
  };

  my $self = $class->SUPER::new ('FREEBUSY', $map, %args);
  return $self;
}

1;
__END__

=head1 SEE ALSO

L<Net::ICal::Period>, L<Net::ICal::Freebusy>. There are a lot of
semantics to handling these for real usage; see RFC2445.

More documentation can also be found in L<Net::ICal>.

=cut
