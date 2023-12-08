#!perl

use strict;
use warnings;

use Test::Most;

use Test::PayProp::API::Public::Emulator;
use PayProp::API::Public::Client::Authorization::APIKey;
use PayProp::API::Public::Client::Authorization::ClientCredentials;

my $SCHEME = 'http';
my $EMULATOR_HOST = '127.0.0.1';

my $Emulator = Test::PayProp::API::Public::Emulator->new(
	scheme => $SCHEME,
	host => $EMULATOR_HOST,
	exec => 'payprop_api_client.pl',
);

use_ok('PayProp::API::Public::Client');

isa_ok(
	my $APIKeyClient = PayProp::API::Public::Client->new(
		scheme => $SCHEME,
		domain => $Emulator->url,
		authorization => PayProp::API::Public::Client::Authorization::APIKey->new( token => 'AgencyAPIKey' )
	),
	'PayProp::API::Public::Client',
	'PayProp::API::Public::Client via PayProp::API::Public::Client::Authorization::APIKey'
);

isa_ok(
	my $ClientCredentialsClient = PayProp::API::Public::Client->new(
		scheme => $SCHEME,
		domain => $Emulator->url,
		authorization => PayProp::API::Public::Client::Authorization::ClientCredentials->new(
			secret => 'test',
			scheme => $SCHEME,
			domain => $Emulator->url,
			client => 'AnotherTestClient',
			application_user_id => 908863,
		),
	),
	'PayProp::API::Public::Client',
	'PayProp::API::Public::Client via PayProp::API::Public::Client::Authorization::ClientCredentials'
);

subtest 'client attributes' => sub {

	foreach my $setup (
		[ 'tags', 'PayProp::API::Public::Client::Request::Tags' ],
		[ 'export', 'PayProp::API::Public::Client::Request::Export' ],
		[ 'entity', 'PayProp::API::Public::Client::Request::Entity' ],
	) {

		my ( $attribute, $class ) = $setup->@*;

		subtest "$attribute -> $class" => sub {

			isa_ok $APIKeyClient->$attribute, $class;

		};

	}

};

done_testing;
