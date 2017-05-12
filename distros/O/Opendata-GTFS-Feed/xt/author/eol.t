use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.18

use Test::More 0.88;
use Test::EOL;

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

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
