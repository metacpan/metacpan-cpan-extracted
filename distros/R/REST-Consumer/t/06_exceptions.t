#! /usr/bin/env perl

use strict;
use warnings;

use REST::Consumer;
use HTTP::Response;
use LWP::UserAgent;
use Test::More tests => 18;

package LWP::UserAgent;
use Data::Dumper;

no warnings 'redefine';
sub request {
	my $self = shift;
	my $http_request = shift;
	if ( $http_request->uri->as_string =~ /\/fail$/) {
		my $response = HTTP::Response->new(500);
		$response->content( $http_request->uri->as_string );
		$response->request($http_request);
		$response->content_type('application/json');
		return $response;
	} elsif ( $http_request->uri->as_string =~ /\/timeout$/) {
		die 'timeout';
	} else {
		my $response = HTTP::Response->new(200);
		$response->content( $http_request->uri->as_string );
		$response->request($http_request);
		$response->content_type('application/json');
		return $response;
	}
}

package main;

REST::Consumer->configure({
	foo => {
		host    => 'localhost',
		retries => 0,
	},
});

is(REST::Consumer->throw_exceptions, 1, "by default we throw exceptions");

{
	my $response;
	eval {
		$response = REST::Consumer->service('foo')->post(
			path => '/fail',
			body => {
				foo => 'bar',
			},
			timeout => 1,
		);
	};
	my $exception = $@;
	isa_ok $exception, "REST::Consumer::RequestException",
		"throws exception objects by default";

	isa_ok $exception->request, "HTTP::Request",
		"exception object has a real request";

	isa_ok $exception->response, "HTTP::Response",
		"exception object has a real response";
}

{
	my $response;
	eval {
		$response = REST::Consumer->service('foo')->post(
			path => '/timeout',
			body => {
				foo => 'bar',
			},
			timeout => 5,
		);
	};
	my $exception = $@;
	ok $exception, "throws exception by default";
	isa_ok(REST::Consumer->service('foo')->last_request, 'HTTP::Request', 'got request');
	is(REST::Consumer->service('foo')->last_response, undef, 'no response for timeout');
}

{
	my $response;
	eval {
		$response = REST::Consumer->service('foo')->post(
			path => '/test',
			body => {
				foo => 'bar',
			},
			timeout => 5,
		);
	};
	my $exception = $@;
	ok !$exception,
		"when we get a successful response there is no exception";
}

{
	REST::Consumer->throw_exceptions(0);
	my $response;
	eval {
		$response = REST::Consumer->service('foo')->post(
			path => '/fail',
			content => {
				foo => 'bar',
			},
			timeout => 5,
		);
	};
	my $exception = $@;
	ok !$exception,
		"when we aren't throwing exceptions, we don't get any for an unsuccessful response";

	isa_ok(REST::Consumer->service('foo')->last_request, "HTTP::Request",
		"we can get back to the request from the consumer");

	isa_ok(REST::Consumer->service('foo')->last_response, "HTTP::Response",
		"we can get back to the response from the consumer");

	ok(!REST::Consumer->service('foo')->last_response->is_success,
		"we can tell that the last response was not successful");

	is(REST::Consumer->service('foo')->last_response->code, 500,
		"the status codes is 500");
}

{
	my $response;
	eval {
		$response = REST::Consumer->service('foo')->post(
			path => '/test',
			content => {
				foo => 'bar',
			},
			timeout => 5,
		);
	};
	my $exception = $@;
	ok !$exception,
		"when we aren't throwing exceptions, we don't get any for a successful response";

	isa_ok(REST::Consumer->service('foo')->last_request, "HTTP::Request",
		"we can get back to the request from the consumer");

	isa_ok(REST::Consumer->service('foo')->last_response, "HTTP::Response",
		"we can get back to the response from the consumer");

	ok(REST::Consumer->service('foo')->last_response->is_success,
		"we can tell that the last response was successful");

	is(REST::Consumer->service('foo')->last_response->code, 200,
		"the status codes is 200");
}
