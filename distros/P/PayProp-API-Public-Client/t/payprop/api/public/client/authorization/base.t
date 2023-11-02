#!perl

use strict;
use warnings;

use Test::Most;


note 'The request methods are tested in respective consumer classes e.g. t/unit/payprop/api/public/client/authorization/clientcredentials.t';

{
	package Test::Authorization;

	use Mouse;
	extends qw/ PayProp::API::Public::Client::Authorization::Base /;

	1;
}

use_ok('Test::Authorization');

isa_ok(
	my $TestAuthorization = Test::Authorization->new(
		token_type => 'APIkey'
	),
	'Test::Authorization',
);

can_ok $TestAuthorization, qw/
	token_request_p
	remove_token_from_storage_p
/;

throws_ok
	{ $TestAuthorization->_token_request_p }
	qr/_token_request_p not implemented/
;

done_testing;
