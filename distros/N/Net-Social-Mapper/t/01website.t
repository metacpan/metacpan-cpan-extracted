#!perl -w

use strict;
use Test::More;

my $tests  = 15;
$tests    += 2 if $ENV{NET_SOCIAL_MAPPER_NETWORK_TESTS};
plan tests => $tests;

my $persona;
use_ok("Net::Social::Mapper::Persona::Website");
ok($persona = Net::Social::Mapper::Persona::Website->new('http://sixapart.com', 'website'), "Created new persona");
is($persona->user,    'http://sixapart.com',               'Got user');
is($persona->service, 'website',                           'Got service');
is($persona->domain,  'sixapart.com',                      'Got domain');


my $mapper;
use_ok("Net::Social::Mapper");
ok($mapper = Net::Social::Mapper->new,                     'Got mapper');
ok($persona  = $mapper->persona('http://sixapart.com'),    'Retrieved persona');
is($persona->user,    'http://sixapart.com',               'Got user');
is($persona->service, 'website',                           'Got service');
is($persona->domain,  'sixapart.com',                      'Got domain');

ok($persona  = $mapper->persona('sixapart.com'),           'Retrieved persona');
is($persona->user,    'http://sixapart.com',               'Got user');
is($persona->service, 'website',                           'Got service');
is($persona->domain,  'sixapart.com',                      'Got domain');



exit 0 unless $ENV{NET_SOCIAL_MAPPER_NETWORK_TESTS};

my @feeds;
ok(@feeds = $persona->feeds,                               'Got feeds');
is($feeds[0], 'http://feeds.feedburner.com/SixApartNews',  'Got correct feed');
