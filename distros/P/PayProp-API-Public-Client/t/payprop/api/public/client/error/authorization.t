#!perl

use strict;
use warnings;

use Test::Most;


use_ok('PayProp::API::Public::Client::Error::Authorization');
isa_ok(
	my $Error = PayProp::API::Public::Client::Error::Authorization->new(
		code => 'code',
		message => 'message',
	),
	'PayProp::API::Public::Client::Error::Authorization',
);

is $Error->code, 'code', '->code';
is $Error->message, 'message', '->message';

done_testing;
