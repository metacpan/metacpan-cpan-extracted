#!perl

use strict;
use warnings;

use Test::Most;


use_ok('PayProp::API::Public::Client::Exception::Base');

throws_ok
	{ PayProp::API::Public::Client::Exception::Base->throw( 1, 2, 3 ) }
	qr/wrong number of args for throw - expected either an error message or pairs/
;

cmp_deeply
	[ PayProp::API::Public::Client::Exception::Base->Fields ],
	[ qw/ status_code errors / ],
	'->Fields'
;

done_testing;
