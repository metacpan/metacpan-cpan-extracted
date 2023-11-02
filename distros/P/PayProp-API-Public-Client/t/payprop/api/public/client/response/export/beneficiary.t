#!perl

use strict;
use warnings;

use Test::Most;


use_ok('PayProp::API::Public::Client::Response::Export::Beneficiary');
isa_ok(
	my $Beneficiary = PayProp::API::Public::Client::Response::Export::Beneficiary->new,
	'PayProp::API::Public::Client::Response::Export::Beneficiary'
);

done_testing;

