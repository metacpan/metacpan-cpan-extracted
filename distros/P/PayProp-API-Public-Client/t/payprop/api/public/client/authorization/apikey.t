#!perl

use strict;
use warnings;

use Test::Most;


use_ok('PayProp::API::Public::Client::Authorization::APIKey');

isa_ok(
	my $APIKeyAuthorization = PayProp::API::Public::Client::Authorization::APIKey->new( token => 'AgencyAPIKey' ),
	'PayProp::API::Public::Client::Authorization::APIKey',
);

is $APIKeyAuthorization->token_type, 'APIkey', 'Got expected token_type';

subtest '->_token_request_p' => sub {

	$APIKeyAuthorization
		->_token_request_p
		->then( sub {
			my ( $token_info ) = @_;

			cmp_deeply
				$token_info,
				{
					token => 'AgencyAPIKey',
					token_type => 'APIkey',
				}
		} )
		->wait
	;

};

done_testing;
