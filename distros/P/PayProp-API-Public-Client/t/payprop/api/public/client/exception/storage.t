#!perl

use strict;
use warnings;

use Test::Most;


use_ok('PayProp::API::Public::Client::Exception::Storage');
throws_ok
	{ PayProp::API::Public::Client::Exception::Storage->throw('This is an error!') }
	'PayProp::API::Public::Client::Exception::Storage'
;

is $@->message, 'This is an error!', '->message';

done_testing;
