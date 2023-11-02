#!perl

use strict;
use warnings;

use JSON::PP;
use Test::Most;
use Test::PayProp::API::Public::Emulator;

use PayProp::API::Public::Client::Authorization::APIKey;


use_ok('PayProp::API::Public::Client::Request::Entity::Payment');

my $SCHEME = 'http';
my $EMULATOR_HOST = '127.0.0.1';

my $Emulator = Test::PayProp::API::Public::Emulator->new(
	scheme => 'http',
	exec => 'payprop_api_client.pl',
	host => $EMULATOR_HOST,
);

isa_ok(
	my $EntityPayment = PayProp::API::Public::Client::Request::Entity::Payment->new(
		scheme => $SCHEME,
		api_version => 'v1.1',
		domain => $Emulator->url,
		authorization => PayProp::API::Public::Client::Authorization::APIKey->new( token => 'AgencyAPIKey' ),
	),
	'PayProp::API::Public::Client::Request::Entity::Payment'
);

is $EntityPayment->url, $Emulator->url . '/api/agency/v1.1/entity/payment', 'Got expected EntityPayment URL';

subtest '->list_p' => sub {

	$Emulator->start;

	$EntityPayment
		->list_p({ path_params => { external_id => 'MZnW5oLYJ7' } })
		->then( sub {
			my ( $Payment ) = @_;

			is $Payment->id, 'MZnW5oLYJ7';
			isa_ok( $Payment, 'PayProp::API::Public::Client::Response::Entity::Payment' );

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
		"start_date" => "2022-04-08",
		"category_id" => "Vv2XlY1ema",
		"property_id" => "mGX0O4zrJ3",
		"use_money_from" => "any_tenant",
		"beneficiary_id" => "B6XK97WwZW",
		"beneficiary_type" => "beneficiary",
		"reference" => "sed suscipit explicabo",
	};

	$EntityPayment
		->create_p( $data )
		->then( sub {
			my ( $Payment ) = @_;

			is $Payment->id, 'nZ3YqdvzXN';
			isa_ok( $Payment, 'PayProp::API::Public::Client::Response::Entity::Payment' );
		} )
		->wait
	;

	$Emulator->stop;

};

subtest '->update_p' => sub {

	$Emulator->start;

	$EntityPayment
		->update_p( { path_params => { external_id => 'MZnW5oLYJ7' } }, { amount => 777 } )
		->then( sub {
			my ( $Payment ) = @_;
			isa_ok( $Payment, 'PayProp::API::Public::Client::Response::Entity::Payment' );
		} )
		->wait
	;

	$Emulator->stop;

};


sub _path_params {
	my ( $self ) = @_;

	return [qw/ external_id /];
}

subtest 'params' => sub {
	cmp_deeply $EntityPayment->_path_params, [qw/ external_id /];
	cmp_deeply $EntityPayment->_query_params, [qw/ is_customer_id /];
};

done_testing;
