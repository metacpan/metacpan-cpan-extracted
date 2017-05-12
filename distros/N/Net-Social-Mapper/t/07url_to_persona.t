#!perl -w

use strict;
use Test::More;

my $tests = 17;
$tests   += 3  if $ENV{NET_SOCIAL_MAPPER_NETWORK_TESTS};
plan tests => $tests;

use_ok("Net::Social::Mapper");
my $mapper;
ok($mapper = Net::Social::Mapper->new, "Got mapper");

my $persona;
ok($persona  = $mapper->persona("http://daveman692.livejournal.com"),                         "Got persona from LJ");
is($persona->user,    "daveman692",                                                           "Got user");
is($persona->service, "livejournal",                                                          "Got service");
ok($persona  = $mapper->persona("http://daveman692.livejournal.com/data/rss"),                "Got persona from LJ feed");
is($persona->user,    "daveman692",                                                           "Got user");
is($persona->service, "livejournal",                                                          "Got service");
ok($persona  = $mapper->persona("http://www.livejournal.com/userinfo.bml?user=daveman692"),   "Got persona from LJ profile"); 
is($persona->user,    "daveman692",                                                           "Got user");
is($persona->service, "livejournal",                                                          "Got service");

ok($persona  = $mapper->persona("http://flickr.com/photos/daveman692/"),                      "Got persona from Flickr");
is($persona->user,    "daveman692",                                                           "Got user");
is($persona->service, "flickr",                                                               "Got service");
ok($persona  = $mapper->persona("http://www.flickr.com/people/daveman692/"),                  "Got service from Flickr profile");
is($persona->user,    "daveman692",                                                           "Got user");
is($persona->service, "flickr",                                                               "Got service");

exit 0 unless $ENV{NET_SOCIAL_MAPPER_NETWORK_TESTS};

ok($persona  = $mapper->persona('http://api.flickr.com/services/feeds/photos_public.gne?id=36381329@N00&amp;lang=en-us&amp;format=atom'),                "Got persona from Flickr feed");
is($persona->user,    "daveman692",                                                           "Got user");
is($persona->service, "flickr",                                                               "Got service");



