#!perl

use strict;
use warnings;

use Test::Most;


use_ok('PayProp::API::Public::Client::Response::Export::Beneficiary::Property');
isa_ok(
	my $Property = PayProp::API::Public::Client::Response::Export::Beneficiary::Property->new,
	'PayProp::API::Public::Client::Response::Export::Beneficiary::Property'
);

done_testing;
