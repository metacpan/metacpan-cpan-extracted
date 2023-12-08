#!perl

use strict;
use warnings;

use JSON::PP;
use Test::Most;
use Test::PayProp::API::Public::Emulator;

use PayProp::API::Public::Client::Authorization::APIKey;


use_ok('PayProp::API::Public::Client::Request::Export::Tenants');

my $SCHEME = 'http';
my $EMULATOR_HOST = '127.0.0.1';

my $Emulator = Test::PayProp::API::Public::Emulator->new(
	scheme => 'http',
	exec => 'payprop_api_client.pl',
	host => $EMULATOR_HOST,
);

isa_ok(
	my $ExportTenants = PayProp::API::Public::Client::Request::Export::Tenants->new(
		scheme => $SCHEME,
		api_version => 'v1.1',
		domain => $Emulator->url,
		authorization => PayProp::API::Public::Client::Authorization::APIKey->new( token => 'AgencyAPIKey' ),
	),
	'PayProp::API::Public::Client::Request::Export::Tenants'
);

is $ExportTenants->url, $Emulator->url . '/api/agency/v1.1/export/tenants', 'Got expected ExportTenants URL';

subtest '->list_p' => sub {

	$Emulator->start;

	$ExportTenants
		->list_p
		->then( sub {
			my ( $tenants, $optional ) = @_;

			is scalar $tenants->@*, 25;
			isa_ok( $tenants->[0], 'PayProp::API::Public::Client::Response::Export::Tenant' );

			cmp_deeply
				$optional,
				{
					pagination => {
						rows => 25,
						page => 1,
						total_pages => 1,
						total_rows => 25,
					}
				},
				'optional args'
			;

		} )
		->wait
	;

	$Emulator->stop;

};

done_testing;
