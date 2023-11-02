#!perl

use strict;
use warnings;

use Test::Most;

use PayProp::API::Public::Client::Authorization::APIKey;


use_ok('PayProp::API::Public::Client::Request::Entity');

isa_ok(
	my $EntityRequest = PayProp::API::Public::Client::Request::Entity->new(
		domain => 'mock.com',
		authorization => PayProp::API::Public::Client::Authorization::APIKey->new( token => 'AgencyAPIKey' )
	),
	'PayProp::API::Public::Client::Request::Entity',
);

isa_ok(
	$EntityRequest->payment,
	'PayProp::API::Public::Client::Request::Entity::Payment',
);

isa_ok(
	$EntityRequest->invoice,
	'PayProp::API::Public::Client::Request::Entity::Invoice',
);

done_testing;
