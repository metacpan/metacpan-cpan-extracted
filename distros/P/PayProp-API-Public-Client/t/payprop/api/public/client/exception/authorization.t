#!perl

use strict;
use warnings;

use Test::Most;


use_ok('PayProp::API::Public::Client::Exception::Authorization');
throws_ok
	{ PayProp::API::Public::Client::Exception::Authorization->throw('This is an error!') }
	'PayProp::API::Public::Client::Exception::Authorization'
;

is $@->message, 'This is an error!', '->message';

subtest 'with ->errors' => sub {

	throws_ok
		{
			PayProp::API::Public::Client::Exception::Authorization->throw(
				status_code => 500,
				errors => [
					{
						code => 'not_good',
						message => 'This is not good!',
					},
				],
			);
		}
		'PayProp::API::Public::Client::Exception::Authorization'
	;

	is $@->status_code, 500, '->status_code';

	is scalar $@->errors->@*, 1, '->errors';
	isa_ok $@->errors->[0], 'PayProp::API::Public::Client::Error::Authorization';

};

done_testing;
