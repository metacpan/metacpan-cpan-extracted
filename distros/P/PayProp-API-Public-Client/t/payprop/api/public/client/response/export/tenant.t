#!perl

use strict;
use warnings;

use Test::Most;


use_ok('PayProp::API::Public::Client::Response::Export::Tenant');
isa_ok(
	my $Tenant = PayProp::API::Public::Client::Response::Export::Tenant->new,
	'PayProp::API::Public::Client::Response::Export::Tenant'
);

done_testing;

