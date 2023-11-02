#!perl

use strict;
use warnings;

use Test::Most;


{
	package Test::Role::Attribute::Domain;

	use Mouse;
	with qw/ PayProp::API::Public::Client::Role::Attribute::Domain /;

	1;
}

throws_ok { Test::Role::Attribute::Domain->new } qr{Attribute \(domain\) is required};

isa_ok(
	my $Domain = Test::Role::Attribute::Domain->new( domain => 'test' ),
	'Test::Role::Attribute::Domain',
);

is $Domain->domain, 'test', '->domain';

done_testing;
