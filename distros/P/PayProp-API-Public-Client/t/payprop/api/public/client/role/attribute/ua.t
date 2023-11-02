#!perl

use strict;
use warnings;

use Test::Most;


{
	package Test::Role::Attribute::UA;

	use Mouse;
	with qw/ PayProp::API::Public::Client::Role::Attribute::UA /;

	1;
}

isa_ok( my $UA = Test::Role::Attribute::UA->new->ua, 'Mojo::UserAgent' );

is $UA->transactor->name, 'PayProp API Client';

done_testing;
