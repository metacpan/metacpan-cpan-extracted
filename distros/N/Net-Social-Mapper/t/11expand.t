#!perl -w

use strict;
use Test::More;
use Net::Social::Mapper;

my %pairs = (
	'http://davidrecordon.com' => 'website',
	'davidrecordon.com'        => 'website',
    'daveman692@livejournal'   => 'livejournal',
    'daveman692@flickr'        => 'flickr',
    '36381329@N00@flickr'      => 'flickr',
    'test@example.com'         => 'email',
);

if ($ENV{NET_SOCIAL_MAPPER_NETWORK_TESTS}) {
	$pairs{'http://api.flickr.com/services/feeds/photos_public.gne?id=36381329@N00&amp;lang=en-us&amp;format=atom'} = 'flickr';
	$pairs{'api.flickr.com/services/feeds/photos_public.gne?id=36381329@N00&amp;lang=en-us&amp;format=atom'} = 'flickr';
}


my $tests = 2*scalar(keys %pairs);
plan tests => $tests;

my $mapper = Net::Social::Mapper->new;

foreach my $string (keys %pairs) {
	my $persona;
	my $service = $pairs{$string};
	ok($persona = $mapper->persona($string),  "Parsed persona for $string");
	is($persona->service, $service,          "Correctly got that service for $string was $service");
}
