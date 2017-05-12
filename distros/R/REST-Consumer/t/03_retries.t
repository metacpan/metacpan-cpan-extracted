#!/usr/bin/env perl
# test that client retries on bad responses
use strict;
use warnings;

use Data::Dumper;
use REST::Consumer;
use HTTP::Response;
use LWP::UserAgent;
use Test::More tests => 14;
use Time::HiRes qw(time);
use Test::Resub qw(resub);

my $request_count = 0;

package LWP::UserAgent;

no warnings 'redefine';
sub request {
	my $self = shift;
	my $http_request = shift;
	$request_count++;
	my $response = HTTP::Response->new(500);
	$response->content( $http_request->content() );
	$response->message('test error');
	$response->request($http_request);
	$response->content_type($http_request->content_type());
	return $response;
}

package main;


{
	my $client = REST::Consumer->new(
		port => 80,
		host => 'localhost',
	);

	# test the interface.  the client will call the mocked LWP::UserAgent::request method above
	# and return the uri string as its response content

	my $error;
	eval {
		my $post_result = $client->post(
			path => '/test/path/to/resource/',
			body => 'test',
		);
		1;
	} or do {
		chomp($error = $@);
	};

	like(
		$error,
		qr/^Request Failed: POST http:\/\/localhost:80\/test\/path\/to\/resource\/ -- 500 test error/,
		'failed request was not retried by default',
	);

	is $request_count, 1,
		'failed request resulted in only a single request by default';
}


$request_count = 0;
{
	my $client = REST::Consumer->new(
		port => 80,
		host => 'localhost',
		retries => 5,
		retry_delay => 1000,
	);

	is $client->retry_delay, 1000, 'retry_delay not successfully set';
	# test the interface.  the client will call the mocked LWP::UserAgent::request method above
	# and return the uri string as its response content

	my $start_time = time();
	my $error;
	eval {
		my $post_result = $client->post(
			path => '/test/path/to/resource/',
			body => 'test',
		);
		1;
	} or do {
		chomp($error = $@);
	};

	like(
		$error,
		qr/^Request Failed after 6 attempts: POST http:\/\/localhost:80\/test\/path\/to\/resource\/ -- 500 test error/,
		'failed request was retried 5 times (6 total attempts) by redefining retries',
	);

	is $request_count, 6,
		'failed request with retry resulted in 6 total requests';
	my $total_s_elapsed = time() - $start_time;
	ok ($total_s_elapsed >= 5,
		"Expected number of seconds were not slept! Got $total_s_elapsed");
}

$request_count = 0;
{
	my $client = REST::Consumer->new(
		port => 80,
		host => 'localhost',
		retries => 5,
	);

	# test the interface.  the client will call the mocked LWP::UserAgent::request method above
	# and return the uri string as its response content

	my $error;
	eval {
		my $post_result = $client->post(
			path => '/test/path/to/resource/',
			body => 'test',
		);
		1;
	} or do {
		chomp($error = $@);
	};

	like(
		$error,
		qr/^Request Failed after 6 attempts: POST http:\/\/localhost:80\/test\/path\/to\/resource\/ -- 500 test error/,
		'failed request was retried 5 times (6 total attempts) by redefining retries',
	);

	is $request_count, 6,
		'failed request with retry resulted in 6 total requests';
}

$request_count = 0;
{
	my $client = REST::Consumer->new(
		port => 80,
		host => 'localhost',
	);

	# test the interface.  the client will call the mocked LWP::UserAgent::request method above
	# and return the uri string as its response content

	my $error;
	eval {
		my $post_result = $client->post(
			path  => '/test/path/to/resource/',
			body  => 'test',
			retry => 2,
		);
	};
	if ($@) {
		chomp($error = $@);
	}

	like(
		$error,
		qr/^Request Failed after 3 attempts: POST http:\/\/localhost:80\/test\/path\/to\/resource\/ -- 500 test error/,
		'failed request was retried 2 times (3 total attempts) by setting retry in the request itself',
	);

	is $request_count, 3,
		'failed request with retry 2 resulted in 3 total requests';
}

$request_count = 0;
{
	my $client = REST::Consumer->new(
		host => 'localhost',
	);

	my $error;
	eval {
		my $post_result = $client->post(
			path  => '/test/path/to/resource/',
			body  => 'test',
			retry => 0,
		);
	};
	if ($@) {
		chomp($error = $@);
	}

	like(
		$error,
		qr/^Request Failed: POST http:\/\/localhost\/test\/path\/to\/resource\/ -- 500 test error/,
		'failed request doesn\'t get retried if retry is 0',
	);

	is $request_count, 1,
		'failed request with retry 0 resulted in 1 total requests';
}

$request_count = 0;
{
	my $client = REST::Consumer->new(
		host => 'localhost',
		retry => 0,
	);

	my $error;
	eval {
		my $post_result = $client->post(
			path  => '/test/path/to/resource/',
			body  => 'test',
		);
	};
	if ($@) {
		chomp($error = $@);
	}

	like(
		$error,
		qr/^Request Failed: POST http:\/\/localhost\/test\/path\/to\/resource\/ -- 500 test error/,
		'failed request doesn\'t get retried if client retries is 0',
	);

	is $request_count, 1,
		'failed request with retry 0 in config resulted in 1 total requests';
}
