#!perl

use strict;
use warnings;

use Test::Most;
use PayProp::API::Public::Client::Authorization::APIKey;


{
	package Test::Role::Authorization;

	use Mouse;
	with qw/ PayProp::API::Public::Client::Role::Attribute::Authorization /;

	1;
}

isa_ok(
	my $Authorization = Test::Role::Authorization->new(
		authorization => PayProp::API::Public::Client::Authorization::APIKey->new( token => 'meh' ),
	),
	'Test::Role::Authorization',
);

done_testing;
