#!perl

use strict;
use warnings;

use Test::Most;
use PayProp::API::Public::Client::Authorization::APIKey;


{
	package Test::Role::APIRequest;

	use Mouse;
	with qw/ PayProp::API::Public::Client::Role::APIRequest /;

	has '+url' => ( default => '/mock/path' );

	sub _query_params { [ qw/ foo bar / ] }

	1;
}

isa_ok(
	my $APIRequest = Test::Role::APIRequest->new(
		domain => 'domain.com',
		authorization => PayProp::API::Public::Client::Authorization::APIKey->new( token => 'meh' ),
	),
	'Test::Role::APIRequest'
);

can_ok $APIRequest, qw/
	api_request_p
/;

subtest 'exceptions' => sub {

	throws_ok
		{ $APIRequest->api_request_p({ method => 'UNNKNOWN' }) }
		qr/method UNNKNOWN not suported for api_request_p/
	;

	throws_ok
		{ $APIRequest->api_request_p({ handle_response_cb => [] }) }
		qr/handle_response_cb must be CODE ref/
	;

};

done_testing;
