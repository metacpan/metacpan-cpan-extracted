#/usr/bin/perl
#
use strict;
use warnings;

use Strava::GPX;

my $url = shift or die "$0 http://app.strava.com/events/Leadville-tahoe-trail-100";

my $s = Strava::GPX->new($url);

print $s->to_gpx;

