#!perl

use strict;
use warnings;

use Test::Most;


use_ok('PayProp::API::Public::Client::Response::Export::Beneficiary::Address');
isa_ok(
	my $Address = PayProp::API::Public::Client::Response::Export::Beneficiary::Address->new,
	'PayProp::API::Public::Client::Response::Export::Beneficiary::Address'
);

done_testing;
