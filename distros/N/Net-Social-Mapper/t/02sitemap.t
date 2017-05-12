#!perl -w

use strict;
use Test::More;

my $tests  =  10; 
plan tests => $tests;

use_ok("Net::Social::Mapper::SiteMap");

my $sitemap;
ok($sitemap = Net::Social::Mapper::SiteMap->new, "Got SiteMap");

my $profile;
ok($profile = $sitemap->profile('livejournal'),                           "Got profile");
is($profile->{domain},     'livejournal.com',                             "Got domain");
is($profile->{homepage},   'http://%user.livejournal.com',                "Got homepage");
is($profile->{feeds}->[0], 'http://%user.livejournal.com/data/atom',      "Got feed");


ok($profile = $sitemap->profile('livejournal', 'daveman692'),             "Got profile again");
is($profile->{domain},     'livejournal.com',                             "Got munged domain");
is($profile->{homepage},   'http://daveman692.livejournal.com',           "Got munged homepage");
is($profile->{feeds}->[0], 'http://daveman692.livejournal.com/data/atom', "Got munged feed");

