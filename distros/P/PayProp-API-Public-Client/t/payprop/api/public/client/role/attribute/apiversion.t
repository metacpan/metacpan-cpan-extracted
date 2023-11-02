#!perl

use strict;
use warnings;

use Test::Most;


{
	package Test::Role::Attribute::APIVersion;

	use Mouse;
	with qw/ PayProp::API::Public::Client::Role::Attribute::APIVersion /;

	1;
}

isa_ok(
	my $APIVersion = Test::Role::Attribute::APIVersion->new,
	'Test::Role::Attribute::APIVersion',
);

is $APIVersion->api_version, 'v1.1', '->api_version';

done_testing;
