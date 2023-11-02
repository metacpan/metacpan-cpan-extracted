#!perl

use strict;
use warnings;

use Test::Most;


use_ok('PayProp::API::Public::Client::Exception::Connection');
throws_ok
	{ PayProp::API::Public::Client::Exception::Connection->throw('This is an error!') }
	'PayProp::API::Public::Client::Exception::Connection'
;

is $@->message, 'This is an error!', '->message';

done_testing;
