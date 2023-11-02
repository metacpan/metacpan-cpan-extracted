#!perl

use strict;
use warnings;

use Test::Most;


{
	package Test::Role::Token;

	use Mouse;
	with qw/ PayProp::API::Public::Client::Role::Attribute::Token /;

	1;
}

throws_ok
	{ Test::Role::Token->new }
	qr/you must override default token_type value/
;

throws_ok
	{ Test::Role::Token->new( token_type => 'badbadbad' ) }
	qr/Attribute \(token_type\) does not pass the type constraint/
;

isa_ok(
	my $Token = Test::Role::Token->new( token_type => 'APIkey' ),
	'Test::Role::Token'
);

done_testing;
