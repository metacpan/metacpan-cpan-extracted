#!/usr/local/bin/perl

use lib '../lib';

use Net::ICal;

# This is to test that Duration is working properly.

my $attendee  = Net::ICal::Attendee->new('shutton');
my $attendee2 = Net::ICal::Attendee->new('davem');
my $attendee3 = Net::ICal::Attendee->new('mini');
my $start     = Net::ICal::Time->new(localtime(time()), 'America/Los_Angeles');
my $dur       = Net::ICal::Duration->new("PT2H0M0S") or die "couldn't create duration";
my $end       = $start->add($dur);

my $event = Net::ICal::Event->new(
				  dtstart   => $start,
				  dtend     => $end,
				  organizer => $attendee,
				  attendee  => [ $attendee2, $attendee3 ],
                  duration => $dur, 
                                 ) ||
  die "Didn't get a valid ICal object";



print $event->as_ical . "\n"; 

