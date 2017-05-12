use strict;
use warnings;

use Test::More;

use Net::Songkick::Country;
use Net::Songkick::MetroArea;
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

my $venue = Net::Songkick::Venue->new({
  id => 17522,
  displayName => 'O2 Brixton Academy',
  city => {
    uri => 'http://www.songkick.com/metro_areas/24426-uk-london',
    displayName => 'London',
    country => { displayName => 'UK' },
    id => 24426,
  },
  metroArea => {
    uri => 'http://www.songkick.com/metro_areas/24426-uk-london',
    displayName => 'London',
    country => { displayName => 'UK' },
    id => 24426,
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
is($venue->id, 17522, 'Got the right venue');
is($venue->displayName, 'O2 Brixton Academy',
   'Venue has the correct name');
isa_ok($venue->metroArea, 'Net::Songkick::MetroArea');
is($venue->metroArea->displayName, 'London',
   'Metro area is in the correct Metro Area');


done_testing;
