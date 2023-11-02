#!perl

use strict;
use warnings;

use Test::Most;


use_ok('PayProp::API::Public::Client::Response::Export::Tenant::Address');
isa_ok(
	my $Address = PayProp::API::Public::Client::Response::Export::Tenant::Address->new,
	'PayProp::API::Public::Client::Response::Export::Tenant::Address'
);

done_testing;
