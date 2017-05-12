#! /usr/bin/env perl

use strict;
use warnings;

use REST::Consumer;
use HTTP::Response;
use LWP::UserAgent;
use Test::More tests => 4;

package LWP::UserAgent;
use Data::Dumper;

no warnings 'redefine';
sub request {
	my $self = shift;
	my $http_request = shift;
	my $response = HTTP::Response->new(200);
	$response->content( $http_request->uri->as_string );
	$response->request($http_request);
	$response->content_type('application/json');
	return $response;
}

package main;

REST::Consumer->configure({
	foo => {
		host => 'localhost',
	},
	bar => {
		host => 'localhost',
		port => '3000',
	},
});

my $client = REST::Consumer->service('foo');

ok $client->isa('REST::Consumer'), 'foo client is a real client object';

is $client->host, 'localhost', 'foo host is localhost';

my $next_client = REST::Consumer->service('foo');

is $client, $next_client, 'Getting another foo client returns the same original one';

my $results = REST::Consumer->service('foo')->get( path => '/');

is $results, 'http://localhost/',
	'GET request to configured service succeeds';

# TODO: test configuration by url
# TODO: test configuration file caching for urls
