use strict;
use warnings FATAL => 'all';
use Test::More;
use Try::Tiny;
use if $ENV{'AUTHOR_TESTING'}, 'Test::Warnings';

plan skip_all => "Skipped http test since GTFS_SKIP_HTTP_TEST is in effect" if $ENV{'GTFS_SKIP_HTTP_TEST'};

eval "use HTTP::Tiny";
plan skip_all => 'HTTP::Tiny required to fetch feeds via http' if $@;

use Test::RequiresInternet ('github.com' => 443);

use File::Temp;
use Opendata::GTFS::Feed;


my $tempdir = File::Temp->newdir();
my $feed;
try {
    $feed = Opendata::GTFS::Feed->new(url => 'https://github.com/Csson/p5-Opendata-GTFS-Feed/raw/master/github/sample-feed.zip', directory => $tempdir);
}
catch {
    if($_ =~ m/\b599\b/) {
        plan skip_all => 'Github errored';
    }
    elsif($_ =~ m{no '/bin/unzip' program found}) {
        plan skip_all => q{Tests needs unzip};
    }
    else {
        die $_;
    }
};

ok 1, 'Fetched zipped feed from google';

is $feed->count_agencies, 1, 'Correct number of agencies';

is $feed->count_calendars, 2, 'Correct number of calendars';

is $feed->count_calendar_dates, 1, 'Correct number of calendar dates';

is $feed->count_fare_attributes, 2, 'Correct number of fare attributes';

is $feed->count_fare_rules, 4, 'Correct number of fare rules';

is $feed->count_frequencies, 11, 'Correct number of frequencies';

is $feed->count_routes, 5, 'Correct number of routes';

is $feed->count_stops, 9, 'Correct number of stops';

is $feed->count_stop_times, 28, 'Correct number of stop times';

is $feed->count_trips, 11, 'Correct number of trips';

done_testing;
