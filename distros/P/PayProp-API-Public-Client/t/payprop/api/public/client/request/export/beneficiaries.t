#!perl

use strict;
use warnings;

use JSON::PP;
use Test::Most;
use Test::PayProp::API::Public::Emulator;

use PayProp::API::Public::Client::Authorization::APIKey;


use_ok('PayProp::API::Public::Client::Request::Export::Beneficiaries');

my $SCHEME = 'http';
my $EMULATOR_HOST = '127.0.0.1';

my $Emulator = Test::PayProp::API::Public::Emulator->new(
	scheme => 'http',
	exec => 'payprop_api_client.pl',
	host => $EMULATOR_HOST,
);

isa_ok(
	my $ExportBeneficiaries = PayProp::API::Public::Client::Request::Export::Beneficiaries->new(
		scheme => $SCHEME,
		api_version => 'v1.1',
		domain => $Emulator->url,
		authorization => PayProp::API::Public::Client::Authorization::APIKey->new( token => 'AgencyAPIKey' ),
	),
	'PayProp::API::Public::Client::Request::Export::Beneficiaries'
);

is $ExportBeneficiaries->url, $Emulator->url . '/api/agency/v1.1/export/beneficiaries', 'Got expected ExportBeneficiaries URL';

subtest '->list_p' => sub {

	$Emulator->start;

	$ExportBeneficiaries
		->list_p
		->then( sub {
			my ( $beneficiaries, $optional ) = @_;

			is scalar $beneficiaries->@*, 2;
			isa_ok( $beneficiaries->[0], 'PayProp::API::Public::Client::Response::Export::Beneficiary' );

			cmp_deeply
				$optional,
				{
					pagination => {
						rows => 2,
						page => 1,
						total_pages => 1,
						total_rows => 2,
					}
				},
				'optional args'
			;

		} )
		->wait
	;

	$Emulator->stop;

};

subtest '->_query_params' => sub {

	cmp_deeply
		$ExportBeneficiaries->_query_params,
		[
			qw/
				rows
				page
				owners
				external_id
				search_by
				search_value
				is_archived
				customer_id
				bank_branch_code
				customer_reference
				modified_from_time
				bank_account_number
				modified_from_timezone
			/
		]
	;

};

done_testing;
