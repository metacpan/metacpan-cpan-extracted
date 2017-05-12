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

my $app = builder {
	enable 'JSON::ForBrowsers' => (
		html_head => '<pre><code>',
		html_foot => '</code></pre>',
	);
	mount '/'  => $json_app;
};
