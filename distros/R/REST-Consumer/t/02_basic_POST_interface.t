#! /usr/bin/env perl
# Test POST request against a mock LWP::UserAgent to verify that the correct uri is produced
use strict;
use warnings;
use Data::Dumper;

use REST::Consumer;
use HTTP::Response;
use LWP::UserAgent;
use URI::QueryParam;
use Test::More tests => 5;

package LWP::UserAgent;
use Data::Dumper;

no warnings 'redefine';
sub request {
	my $self = shift;
	my $http_request = shift;
	my $response = HTTP::Response->new(200);
	$response->content( $http_request->content() );
	$response->request($http_request);
	$response->content_type($http_request->content_type());
	return $response;
}

package main;

my $client = REST::Consumer->new(
	port => 80,
	host => 'localhost',
);

# simple form
my $post_result = $client->get(
	path => '/test/path/to/resource',
	params => {
		foo => 'bar',
		qux => 'baz',
	}
);

my $uri = $client->last_request->uri;
is $uri->path, '/test/path/to/resource',
	'GET with query string params has correct path';
is_deeply $uri->query_form_hash, { qux => 'baz', foo => 'bar' },
	'GET with query string params has correct params';

# test the interface.  the client will call the mocked LWP::UserAgent::request method above
# and return the uri string as its response content
$post_result = $client->post(
	path => '/test/path/to/resource/',
	content_type => 'application/json',
	body => {
		100 => {
			keywords => [qw(a b c)],
		}
	}
);

is_deeply(
	$post_result,
	{
		100 => {
			keywords => [qw(a b c)],
		}
	},
	'POST request sends content body',
);


my $post_response = $client->get_response(
	method => 'POST',
	path => '/path/to/resource',
	content_type => 'multipart/form-data',
	content => [
		animal => 'monkey',
		eats => 'banana',
		eats => 'leaf',
		data => {
			a => [1,2,3],
		},
	],
);

is_deeply(
	$post_response->content(),
	[
		animal => 'monkey',
		eats => 'banana',
		eats => 'leaf',
		data => {
			a => [1,2,3],
		},
	],
	'posted multipart/form-data',
);

is $post_response->content_type, 'multipart/form-data',
	"make sure we actually posted multipart/form-data";
