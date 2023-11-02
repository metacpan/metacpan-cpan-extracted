#!perl

use strict;
use warnings;

use Test::Most;


use_ok('PayProp::API::Public::Client::Exception::Response');
throws_ok
	{ PayProp::API::Public::Client::Exception::Response->throw('This is an error!') }
	'PayProp::API::Public::Client::Exception::Response'
;

is $@->message, 'This is an error!', '->message';

subtest 'with ->errors' => sub {

	throws_ok
		{
			PayProp::API::Public::Client::Exception::Response->throw(
				status_code => 401,
				errors => [
					{
						path => 'path',
						message => 'This is not good!',
					},
				],
			);
		}
		'PayProp::API::Public::Client::Exception::Response'
	;

	is $@->status_code, 401, '->status_code';

	is scalar $@->errors->@*, 1, '->errors';
	isa_ok $@->errors->[0], 'PayProp::API::Public::Client::Error::Response';

};

done_testing;
