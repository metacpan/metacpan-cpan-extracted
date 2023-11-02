#!perl

use strict;
use warnings;

use Test::Most;
use FindBin qw/ $Bin /;

use lib "$Bin/../lib";

use Test::PayProp::API::Public::Emulator;
use MIME::Base64 qw//;



use_ok('PayProp::API::Public::Client::Authorization::ClientCredentials');

my $SCHEME = 'http';
my $EMULATOR_HOST = '127.0.0.1';

my $Emulator = Test::PayProp::API::Public::Emulator->new(
	scheme => $SCHEME,
	host => $EMULATOR_HOST,
	exec => 'payprop_api_client.pl',
);

isa_ok(
	my $ClientCredentials = PayProp::API::Public::Client::Authorization::ClientCredentials->new(
		secret => 'test',
		scheme => $SCHEME,
		domain => $Emulator->url,
		client => 'AnotherTestClient',
		application_user_id => '908863',
	),
	'PayProp::API::Public::Client::Authorization::ClientCredentials'
);

subtest 'attributes' => sub {

	is $ClientCredentials->token_type, 'Bearer', '->token_type';
	like $ClientCredentials->url, qr{/api/oauth/access_token$}, '->url';
	is $ClientCredentials->storage_key, 'ClientCredentials|AnotherTestClient|908863', '->storage_key';

	subtest '->_encoded_key' => sub {

		is $ClientCredentials->_encoded_key, 'QW5vdGhlclRlc3RDbGllbnQ6dGVzdA==';
		is MIME::Base64::decode_base64( $ClientCredentials->_encoded_key ), 'AnotherTestClient:test';

	};

};

subtest '->_query_params' => sub {

	cmp_deeply
		$ClientCredentials->_query_params,
		[ qw/ grant_type application_user_id / ]
	;

};

subtest '->_token_request_p' => sub {

	$Emulator->start;

	my $original_url = $ClientCredentials->url;

	subtest 'error' => sub {

		# request emulator to return 401 status code and error JSON response
		$ClientCredentials->url( $original_url . '?_status_code=401' );

		$ClientCredentials
			->_token_request_p
			->catch( sub {
				my ( $Exception ) = @_;

				is ref( $Exception ), 'PayProp::API::Public::Client::Exception::Authorization', 'exception type';
				is $Exception->status_code, 401, '->status_code';

				is scalar $Exception->errors->@*, 1, 'error count';
				is $Exception->errors->[0]->code, 'access_denied', '->code';
				is $Exception->errors->[0]->message, 'invalid entity access', '->message';

			} )
			->wait
		;

	};

	subtest 'success' => sub {

		$ClientCredentials->url( $original_url );

		$ClientCredentials
			->_token_request_p
			->then( sub {
				my ( $token_info ) = @_;

				cmp_deeply
					$token_info,
					{
						token_type => 'Bearer',
						token => 'ACCESS_TOKEN',
					},
					'token info'
				;

			} )
			->wait
		;

	};

	$Emulator->stop;

};

done_testing;
