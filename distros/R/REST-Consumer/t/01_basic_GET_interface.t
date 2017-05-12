#! /usr/bin/env perl
# Test GET request against a mock LWP::UserAgent to verify that the correct uri is produced
use strict;
use warnings;
use Data::Dumper;

use REST::Consumer;
use HTTP::Response;
use LWP::UserAgent;
use Test::More tests => 3;

package LWP::UserAgent;
use Data::Dumper;

no warnings 'redefine';
sub request {
	my $self = shift;
	my $http_request = shift;
	my $response = HTTP::Response->new(200);
	$response->content( $http_request->uri()->as_string() );
	$response->request($http_request);
	$response->content_type('application/json');
	return $response;
}

package main;

my $client = REST::Consumer->new(
	host => 'localhost',
);

# test the interface.  the client will call the mocked LWP::UserAgent::request method above
# and return the uri string as its response content
my $get_result = $client->get(
	path => '/test/path/to/resource/',
	params => [
		id     => 100,
		field1 => 'abcdef',
		field3 => '花',
	],
);

is(
	$get_result,
	'http://localhost/test/path/to/resource/?id=100&field1=abcdef&field3=%E8%8A%B1',
	'GET request produces expected results based on input params',
);


$get_result = $client->get(
	path => '/test/:test_id/question/:answer',
	params => {
		test_id => 2001,
		answer  => 'yep',
		field3  => '花',
	},
);

is $get_result, 'http://localhost/test/2001/question/yep?field3=%E8%8A%B1',
	'GET request supports sinatra-like colon values';

$get_result = $client->get(
	path => '/test/:test_id/question/:answer',
	params => {
		test_id => 2001,
		answer  => 'Test%sing',
		field3  => 'Field%8dthree',
	},
);

like $get_result, qr[http://localhost/test/2001/question/Test%25sing],
	'GET request works when there are percents in values';

