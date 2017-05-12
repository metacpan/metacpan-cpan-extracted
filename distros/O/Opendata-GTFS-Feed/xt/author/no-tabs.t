use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Opendata/GTFS/Feed.pm',
    'lib/Opendata/GTFS/Feed/Elk.pm',
    'lib/Opendata/GTFS/Type/Agency.pm',
    'lib/Opendata/GTFS/Type/Calendar.pm',
    'lib/Opendata/GTFS/Type/CalendarDate.pm',
    'lib/Opendata/GTFS/Type/FareAttribute.pm',
    'lib/Opendata/GTFS/Type/FareRule.pm',
    'lib/Opendata/GTFS/Type/Frequency.pm',
    'lib/Opendata/GTFS/Type/Route.pm',
    'lib/Opendata/GTFS/Type/Shape.pm',
    'lib/Opendata/GTFS/Type/Stop.pm',
    'lib/Opendata/GTFS/Type/StopTime.pm',
    'lib/Opendata/GTFS/Type/Transfer.pm',
    'lib/Opendata/GTFS/Type/Trip.pm',
    'lib/Types/Opendata/GTFS.pm'
);

notabs_ok($_) foreach @files;
done_testing;
