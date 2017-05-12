#!/usr/bin/env perl
use strict;
use warnings;
use Protocol::SPDY;

my $spdy = Protocol::SPDY::Server->new;
$spdy->on_stream(sub {
	my $stream = shift;
});
	fin => 1,
	headers => [
		':method'  => 'GET',
		':path'    => '/static.txt',
		':version' => 'HTTP/1.1',
		':host'    => 'spdy-test.perlsite.co.uk',
		':scheme'  => 'https',
	]
)->replied->on_done(sub {
	my $stream = shift;
	say "Received response: " . join ' ', $stream->response_header(':status'), $stream->response_header(':version');
	my $buffer = '';
	$stream->on_headers(sub {
	});
	$stream->on_data(sub {
		$buffer .= shift;
		say "Data: $1" while s/^(.*)\n//;
	})
})->closed->on_done(sub {
	say "Request complete";
});

