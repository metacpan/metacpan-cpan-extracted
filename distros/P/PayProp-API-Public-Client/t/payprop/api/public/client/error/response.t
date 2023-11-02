#!perl

use strict;
use warnings;

use Test::Most;


use_ok('PayProp::API::Public::Client::Error::Response');
isa_ok(
	my $Error = PayProp::API::Public::Client::Error::Response->new(
		path => 'path',
		message => 'message',
	),
	'PayProp::API::Public::Client::Error::Response',
);

is $Error->path, 'path', '->path';
is $Error->message, 'message', '->message';

done_testing;
