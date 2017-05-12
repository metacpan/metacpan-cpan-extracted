#!perl -w

use strict;
use Test::More;

my $tests = 1;
$tests   += 10 if $ENV{NET_SOCIAL_MAPPER_NETWORK_TESTS};

plan tests => $tests;

use_ok("Net::Social::Mapper");

exit 0 unless $ENV{NET_SOCIAL_MAPPER_NETWORK_TESTS};

my $mapper;
ok($mapper  = Net::Social::Mapper->new,                         "Got mapper");
my $persona;
ok($persona = $mapper->persona("http://davidrecordon.com"),     "Got persona");
is($persona->user,    "http://davidrecordon.com",               "Got user");
is($persona->service, "website",                                "Got service");

my @elsewhere;
ok(@elsewhere = $persona->elsewhere,                            "Got elsewhere");

my ($lj)      = grep { $_->service eq 'livejournal' } @elsewhere;
ok($lj,                                                         "Found LJ");
is($lj->user, 'daveman692',                                     "Got correct LJ user name");

my ($flickr)  = grep { $_->service eq 'flickr' } @elsewhere;
ok($flickr,                                                     "Found Flickr");
is($flickr->user, 'daveman692',                                 "Got correct Flickr user name");
is($flickr->id,   '36381329@N00',                               "Got Flickr ID");

