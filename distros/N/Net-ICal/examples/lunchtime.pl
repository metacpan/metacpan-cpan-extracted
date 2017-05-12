#!/usr/bin/perl

use strict;
use warnings;

use lib '../lib';
use Net::ICal;

print
"This example is probably wrong unless you are in timezone US/East.
Timezone handling in Net::ICal is something we are actively working
on, but for right now this code is fairly broken. You probably
want to look at the source code of this to see what we commented out.
Eventually, Net::ICal::Timezone.pm, in development, will handle some
of this.
----------------------------------------------------------------------
";


my $now = Net::ICal::Time->new(time(), timezone => 'US/Pacific');
print "Current time is DTSTART", $now->as_ical, "\n";
my $lunchtime = $now->clone;
$lunchtime->hour(12);
$lunchtime->minute(0);
$lunchtime->second(0);

print "Lunch time is/was DTSTART", $lunchtime->as_ical, "\n";
my $indiana = $lunchtime->clone();
$indiana->timezone('US/East-Indiana');
print "In Indiana, that time would be DTSTART", $indiana->as_ical, "\n";
#print "  or ", $indiana->format("%c (Native)\n");
foreach my $tz (qw(US/Mountain Israel Europe/Helsinki UTC Indian/Kerguelen)) {
#  print "  or ", $indiana->format("%c ($tz)\n", $tz);
}

__END__

# This will work in a future release, once we get arithmetic working properly
# The idea is to transpose lunch into different timezones. 

my $lunch_in_indiana = $indiana->add(Net::ICal::Duration->new('P1D'));
$lunch_in_indiana->hour(12);
my $hours_til_lunch = $lunch_in_indiana->subtract($now);
print "Indiana will (or did) celebrate lunch at ",
      $lunch_in_indiana->as_ical_value, "\n";
print "It will be lunchtime in Indiana in ",
      $hours_til_lunch->as_ical_value, "\n";
