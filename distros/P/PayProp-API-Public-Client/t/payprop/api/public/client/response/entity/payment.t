#!perl

use strict;
use warnings;

use Test::Most;


use_ok('PayProp::API::Public::Client::Response::Entity::Payment');
isa_ok(
	my $Payment = PayProp::API::Public::Client::Response::Entity::Payment->new,
	'PayProp::API::Public::Client::Response::Entity::Payment'
);

done_testing;
