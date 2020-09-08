use strict;
use warnings;

use Test::More;

use Net::Songkick;

my @url_tests = ({
  method => 'api_url',
  url    => 'http://api.songkick.com/api/3.0',
  desc   => 'API Base',
}, {
  method => 'events_url',
  url    => 'http://api.songkick.com/api/3.0/events',
  desc   => 'Event',
}, {
  method => 'user_events_url',
  url    => 'http://api.songkick.com/api/3.0/users/USERNAME/events',
  desc   => 'User Events',
}, {
  method => 'user_gigs_url',
  url    => 'http://api.songkick.com/api/3.0/users/USERNAME/gigography',
  desc   => 'User Gigs',
}, {
  method => 'artists_url',
  url    => 'http://api.songkick.com/api/3.0/artists/ARTIST_ID/calendar',
  desc   => 'Artists',
}, {
  method => 'artists_mb_url',
  url    => 'http://api.songkick.com/api/3.0/artists/mbid:MB_ID/calendar',
  desc   => 'Artists MB',
}, {
  method => 'metro_url',
  url    => 'http://api.songkick.com/api/3.0/metro/METRO_ID/calendar',
  desc   => 'Metro',
}, {
  method => 'venue_events_url',
  url    => 'http://api.songkick.com/api/3.0/venues/VENUE_ID/calendar',
  desc   => 'Venue Events',
});

my $ns = Net::Songkick->new({ api_key => 'dummy' });

foreach my $test (@url_tests) {
  can_ok($ns, my $method = $test->{method});
  ok(my $url = $ns->$method, "Got $test->{desc} URL");
  is($url, $test->{url}, "$test->{desc} URL is correct");
}

done_testing;

