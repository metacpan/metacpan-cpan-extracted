use strict;
use warnings;

use Test::More;

use Net::Songkick::Artist;
use Net::Songkick::Country;
use Net::Songkick::MetroArea;
use Net::Songkick::MusicBrainz;
use Net::Songkick::Types;
use Net::Songkick::Venue;

my $country = Net::Songkick::Country->new({ displayName => 'UK' });

ok($country, 'Got an object');
isa_ok($country, 'Net::Songkick::Country');
is($country->displayName, 'UK', 'Got the correct country');

my $metro = Net::Songkick::MetroArea->new({
  id => '9999',
  displayName => 'London',
  country => { displayName => 'UK' },
});

ok($metro, 'Got an object');
isa_ok($metro, 'Net::Songkick::MetroArea');
is($metro->id, '9999', 'Metro area has correct id');
is($metro->displayName, 'London', 'Metro area has correct name');
isa_ok($metro->country, 'Net::Songkick::Country');
is($metro->country->displayName, 'UK',
   'Metro area is in the correct country');

my $city = Net::Songkick::City->new({
    id => '24426',
    displayName => 'London',
    uri => 'http://www.songkick.com/metro_areas/24426-uk-london',
    country => $country
});

ok($city, 'Got an object');
isa_ok($city, 'Net::Songkick::City');
is($city->id, '24426', 'City has correct id');
is($city->displayName, 'London', 'City has correct name');
is($city->uri,'http://www.songkick.com/metro_areas/24426-uk-london',
   'City has correct URI');
isa_ok($city->country, 'Net::Songkick::Country');
is($city->country->displayName, 'UK',
  'City is in the correct country');

my $venue = Net::Songkick::Venue->new({
  id => 17_522,
  displayName => 'O2 Brixton Academy',
  city => {
    uri => 'http://www.songkick.com/metro_areas/24426-uk-london',
    displayName => 'London',
    country => { displayName => 'UK' },
    id => 24_426,
  },
  metroArea => {
    uri => 'http://www.songkick.com/metro_areas/24426-uk-london',
    displayName => 'London',
    country => { displayName => 'UK' },
    id => 24_426,
  },
  uri => 'http://www.songkick.com/venues/17522-o2-academy-brixton',
  street => '211 Stockwell Road',
  zip => 'SW9 9SL',
  lat => 51.4651268,
  lng => -0.115187,
  phone => '020 7771 3000',
  website => 'http://www.brixton-academy.co.uk',
  capacity => 4921,
  description => 'Brixton Academy is an award winning music venue ...',
});

ok($venue, 'Got a venue');
isa_ok($venue, 'Net::Songkick::Venue');
is($venue->id, 17_522, 'Got the right venue');
is($venue->displayName, 'O2 Brixton Academy',
   'Venue has the correct name');
isa_ok($venue->metroArea, 'Net::Songkick::MetroArea');
# Backwards compatibility
isa_ok($venue->metro_area, 'Net::Songkick::MetroArea');
is($venue->metroArea->displayName, 'London',
   'Metro area is in the correct Metro Area');

my $identifier = Net::Songkick::MusicBrainz->new({
  href => 'http://api.songkick.com/api/3.0/artists/mbid:a74b1b7f-71a5-4011-9441-d0b5e4122711.json',
  mbid => 'a74b1b7f-71a5-4011-9441-d0b5e4122711'
});
ok($identifier, 'Got a MusicBrainz array');
isa_ok($identifier, 'Net::Songkick::MusicBrainz');
is($identifier->href,
   'http://api.songkick.com/api/3.0/artists/mbid:a74b1b7f-71a5-4011-9441-d0b5e4122711.json',
   'Identifier has the correct href');
is($identifier->mbid, 'a74b1b7f-71a5-4011-9441-d0b5e4122711',
   'Identifier has the correct mbid');


my $artist = Net::Songkick::Artist->new({
  id => '253846',
  displayName => 'Radiohead',
  uri => 'http://www.songkick.com/artists/253846-radiohead?utm_source=45852&utm_medium=partner',
  identifier => [$identifier],
  onTourUntil => '2018-04-25'
});
ok($artist, 'Got an artist');
isa_ok($artist, 'Net::Songkick::Artist');
is($artist->id, '253846', 'Got the right artist');
is($artist->displayName, 'Radiohead', 'Artist has the correct name');
is($artist->uri,
   'http://www.songkick.com/artists/253846-radiohead?utm_source=45852&utm_medium=partner',
   'Artist has the correct URI');
isa_ok($artist->onTourUntil, 'DateTime');
is( ''. $artist->onTourUntil,
   ''. DateTime::Format::Strptime->new(
        pattern => '%Y-%m-%d',
      )->parse_datetime('2018-04-25'),
   'Artist is on tour');
isa_ok($artist->identifier->[0], 'Net::Songkick::MusicBrainz');
is($artist->identifier->[0]->mbid,
   'a74b1b7f-71a5-4011-9441-d0b5e4122711',
   'Artist has the correct identifier'
);


done_testing;
