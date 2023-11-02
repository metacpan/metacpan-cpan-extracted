#!perl

use strict;
use warnings;

use Test::Most;

use PayProp::API::Public::Client::Authorization::APIKey;


use_ok('PayProp::API::Public::Client::Request::Export');

isa_ok(
	my $ExportRequest = PayProp::API::Public::Client::Request::Export->new(
		domain => 'mock.com',
		authorization => PayProp::API::Public::Client::Authorization::APIKey->new( token => 'AgencyAPIKey' )
	),
	'PayProp::API::Public::Client::Request::Export',
);

isa_ok(
	$ExportRequest->beneficiaries,
	'PayProp::API::Public::Client::Request::Export::Beneficiaries',
);

isa_ok(
	$ExportRequest->tenants,
	'PayProp::API::Public::Client::Request::Export::Tenants',
);

done_testing;
