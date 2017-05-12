#!/usr/local/bin/perl -w

use strict;
use lib '../lib';
use Net::ICal;
use Net::ICal::Timezone;

# This script exists just to be a simple developer's 
# testing box for Net::ICal::Timezone.
#
# KNOWN BUG: the modules aren't interpreting the DAYLIGHT
# section as a DAYLIGHT but as a STANDARD. Patches welcome. 

my $text = calfile();
#print $text;
my $c = Net::ICal::Calendar->new_from_ical( $text) || 
    die "couldn't read calendar in";

print $c->as_ical;

# keep the data segment down at the bottom.
sub calfile {
    # TODO: add a DAYLIGHT section to this and make N::I::Daylight.pm
    
    my $rawtext = 
'BEGIN:VCALENDAR
PRODID:-//Ximian//NONSGML Evolution Olson-VTIMEZONE Converter//EN
VERSION:2.0
BEGIN:VTIMEZONE
TZID:/softwarestudio.org/Olson_20010626_2/Africa/Cairo
BEGIN:STANDARD
TZOFFSETFROM:+0000
TZOFFSETTO:+0205
TZNAME:LMT
DTSTART:00010101T000000
RDATE:00010101T000000
END:STANDARD
BEGIN:DAYLIGHT
TZOFFSETFROM:+0200
TZOFFSETTO:+0300
TZNAME:EEST
DTSTART:19950428T000000
RRULE:FREQ=YEARLY;BYMONTH=4;BYDAY=-1FR
END:DAYLIGHT
END:VTIMEZONE
END:VCALENDAR
';
    return $rawtext;
}
