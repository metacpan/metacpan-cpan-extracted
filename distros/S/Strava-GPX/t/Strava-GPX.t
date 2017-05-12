#/usr/bin/perl
#
use strict;
use warnings;

use Test::More tests => 2;
BEGIN { use_ok('Strava::GPX') };


my $s = Strava::GPX->new('http://app.strava.com/events/Leadville-tahoe-trail-100');

my $xml = $s->to_gpx;

ok($xml);

