#!perl

use strict;
use warnings;

use Test::Most;

use_ok('PayProp::API::Public::Client::Response::Tag');
isa_ok(
	my $Tag = PayProp::API::Public::Client::Response::Tag->new,
	'PayProp::API::Public::Client::Response::Tag'
);

done_testing;
