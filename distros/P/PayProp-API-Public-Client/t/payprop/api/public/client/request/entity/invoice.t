#!perl

use strict;
use warnings;

use JSON::PP;
use Test::Most;
use Test::PayProp::API::Public::Emulator;

use PayProp::API::Public::Client::Authorization::APIKey;


use_ok('PayProp::API::Public::Client::Request::Entity::Invoice');

my $SCHEME = 'http';
my $EMULATOR_HOST = '127.0.0.1';

my $Emulator = Test::PayProp::API::Public::Emulator->new(
	scheme => 'http',
	exec => 'payprop_api_client.pl',
	host => $EMULATOR_HOST,
);

isa_ok(
	my $EntityInvoice = PayProp::API::Public::Client::Request::Entity::Invoice->new(
		scheme => $SCHEME,
		api_version => 'v1.1',
		domain => $Emulator->url,
		authorization => PayProp::API::Public::Client::Authorization::APIKey->new( token => 'AgencyAPIKey' ),
	),
	'PayProp::API::Public::Client::Request::Entity::Invoice'
);

is $EntityInvoice->url, $Emulator->url . '/api/agency/v1.1/entity/invoice', 'Got expected EntityInvoice URL';

subtest '->list_p' => sub {

	$Emulator->start;

	$EntityInvoice
		->list_p({
			path_params => { external_id => 'Vv2XlY1ema' },
		})
		->then( sub {
			my ( $Invoice ) = @_;

			is $Invoice->id, 'Vv2XlY1ema';
			isa_ok( $Invoice, 'PayProp::API::Public::Client::Response::Entity::Invoice' );

		} )
		->wait
	;

	$Emulator->stop;

};

subtest '->create_p' => sub {

	$Emulator->start;

	my $data = {
		"amount" => 850.0,
		"frequency" => "M",
		"payment_day" => 8,
		"tenant_id" => "8EJAnqDyXj",
		"start_date" => "2022-04-08",
		"category_id" => "Vv2XlY1ema",
		"property_id" => "mGX0O4zrJ3",
	};

	$EntityInvoice
		->create_p({ content => $data })
		->then( sub {
			my ( $Invoice ) = @_;

			is $Invoice->id, 'WrJvLzqD1l';
			isa_ok( $Invoice, 'PayProp::API::Public::Client::Response::Entity::Invoice' );
		} )
		->wait
	;

	$Emulator->stop;

};

subtest '->update_p' => sub {

	$Emulator->start;

	$EntityInvoice
		->update_p({
			content => { amount => 777 },
			path_params => { external_id => 'Vv2XlY1ema' },
		})
		->then( sub {
			my ( $Invoice ) = @_;
			isa_ok( $Invoice, 'PayProp::API::Public::Client::Response::Entity::Invoice' );
		} )
		->wait
	;

	$Emulator->stop;

};

done_testing;
