#!perl -w

use strict;
use Test::More;

my $tests = 13;
plan tests => $tests;

my $mapper;
use_ok("Net::Social::Mapper");
ok($mapper = Net::Social::Mapper->new,                                "Got mapper");
my $persona;    
ok(!($persona  = $mapper->persona('daveman692', 'fictious_site')),    "Correctly didn't get bogus persona");
ok($persona  = $mapper->persona('daveman692', 'livejournal'),         "Retrieved persona");
is($persona->user,     'daveman692',                                  "Got user");
is($persona->service,  'livejournal',                                 "Got service");
is($persona->domain,   'livejournal.com',                             "Got domain");
is($persona->homepage, 'http://daveman692.livejournal.com',           "Got homepage");
is($persona->profile,  'http://daveman692.livejournal.com/profile',   "Got profile");
is($persona->foaf,     'http://daveman692.livejournal.com/data/foaf', "Got foaf");
my @feeds;
ok(@feeds = $persona->feeds,                                          "Got feeds");
is(scalar(@feeds), 2,                                                 "Got 2 feeds");
is_deeply([sort(@feeds)], ['http://daveman692.livejournal.com/data/atom', 'http://daveman692.livejournal.com/data/rss'], "Got correct feeds");

