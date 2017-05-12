#!perl -T

use Test::More tests => 9;
use Test::Warn;
use Test::Exception;

BEGIN {
	use_ok( 'Net::Geohash' );
}

warning_is {
    Net::Geohash::get()
} 'Missing lattitude/longitude param';

warning_is {
    Net::Geohash::get('')
} 'Missing lattitude/longitude param';

warning_is {
    Net::Geohash::get(qw/nick is awesome/)
} 'Extra parameters found.';

is(Net::Geohash::get('37.371066 -121.994999'), 'http://geohash.org/9q9hxgjynrxs', 'Sunnyvale, CA');
is(Net::Geohash::get('37.77916 -122.420049'), 'http://geohash.org/9q8yym2rw1g7', 'San Francisco, CA');
is(Net::Geohash::get('40.71455 -74.007124'), 'http://geohash.org/dr5regvemn0x', 'New York, NY');

is(Net::Geohash::get('nick'), 'http://geohash.org/u2kjem2gck9w', 'Nick');
is(Net::Geohash::get('Paris, France'), 'http://geohash.org/u09tvqpftyyf', 'Paris, France');
