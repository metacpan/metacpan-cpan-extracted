use strict;
use warnings FATAL => 'all';
use Test::More;
use if $ENV{'AUTHOR_TESTING'}, 'Test::Warnings';

use Opendata::GTFS::Feed;

ok 1;

my $feed = Opendata::GTFS::Feed->new(directory => 't/corpus/gtfs/');

is $feed->count_agencies, 1, 'Correct number of agencies';

is $feed->count_calendars, 2, 'Correct number of calendars';

is $feed->count_calendar_dates, 1, 'Correct number of calendar dates';

is $feed->count_fare_attributes, 2, 'Correct number of fare attributes';

is $feed->count_fare_rules, 4, 'Correct number of fare rules';

is $feed->count_frequencies, 11, 'Correct number of frequencies';

is $feed->count_routes, 5, 'Correct number of routes';

is $feed->count_shapes, 3, 'Correct number of shapes';

is $feed->count_stops, 9, 'Correct number of stops';

is $feed->count_stop_times, 28, 'Correct number of stop times';

is $feed->count_transfers, 1, 'Correct number of transfers';

is $feed->count_trips, 11, 'Correct number of trips';

done_testing;
