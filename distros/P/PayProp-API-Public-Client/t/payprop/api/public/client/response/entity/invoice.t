#!perl

use strict;
use warnings;

use Test::Most;


use_ok('PayProp::API::Public::Client::Response::Entity::Invoice');
isa_ok(
	my $Invoice = PayProp::API::Public::Client::Response::Entity::Invoice->new,
	'PayProp::API::Public::Client::Response::Entity::Invoice'
);

done_testing;
