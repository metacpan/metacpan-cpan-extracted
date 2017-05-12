#!/usr/bin/env plackup

use strict;
use warnings;

use Plack::Builder;
use Encode;

my $json_app = sub { return [
	200,
	[ 'Content-Type' => 'application/json' ],
	[ encode('UTF-8', "{\"foo\":\"bar, \x{263a}, \x{fc}\",\"<h1>baz</h1>\":2}") ]
] };

my $other_app = sub { return [
	200,
	[ 'Content-Type' => 'text/plain' ],
	[ 'Hello, world!' ]
] };

my $app = builder {
	enable 'JSON::ForBrowsers';
	mount '/json'  => $json_app;
	mount '/other' => $other_app;
};
