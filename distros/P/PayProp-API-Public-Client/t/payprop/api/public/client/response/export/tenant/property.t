#!perl

use strict;
use warnings;

use Test::Most;


use_ok('PayProp::API::Public::Client::Response::Export::Tenant::Property');
isa_ok(
	my $Property = PayProp::API::Public::Client::Response::Export::Tenant::Property->new,
	'PayProp::API::Public::Client::Response::Export::Tenant::Property'
);

done_testing;
