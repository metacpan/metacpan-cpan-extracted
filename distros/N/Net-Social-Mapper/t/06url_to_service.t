#!perl -w

use strict;
use Test::More;

my $tests = 21;
plan tests => $tests;

use_ok("Net::Social::Mapper");
my $mapper;
ok($mapper = Net::Social::Mapper->new, "Got mapper");
my $sitemap;
ok($sitemap  = $mapper->sitemap, "Got sitemap");

my ($user, $service);

ok(($user, $service)  = $sitemap->url_to_service("http://daveman692.livejournal.com"), "Got service from LJ");
is($user,    "daveman692",  "Got user");
is($service, "livejournal", "Got service");
ok(($user, $service)  = $sitemap->url_to_service("http://daveman692.livejournal.com/data/rss"), "Got service from LJ feed");
is($user,    "daveman692",  "Got user");
is($service, "livejournal", "Got service");
ok(($user, $service)  = $sitemap->url_to_service("http://www.livejournal.com/userinfo.bml?user=daveman692"), "Got service from LJ userinfo");
is($user,    "daveman692",  "Got user");
is($service, "livejournal", "Got service");

ok(($user, $service)  = $sitemap->url_to_service("http://flickr.com/photos/daveman692/"), "Got service from Flickr");
is($user,    "daveman692",  "Got user");
is($service, "flickr", "Got service");
ok(($user, $service)  = $sitemap->url_to_service("http://www.flickr.com/people/daveman692/"), "Got service from Flickr profile");
is($user,    "daveman692",  "Got user");
is($service, "flickr", "Got service");

ok(($user, $service)  = $sitemap->url_to_service("http://davidrecordon.com/"), "Got service from Homepage");
is($user,    "http://davidrecordon.com/",  "Got url as user");
is($service, "website",                    "Got service");


