#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use Test::Exception;

{
	package Credit;
	use Moose;
	use MooseX::Types::CreditCard qw( CardSecurityCode );

	has cvv2 => (
		is => 'ro',
		isa => CardSecurityCode,
	);

	__PACKAGE__->meta->make_immutable;
}

my $error
	= 'Attribute \(cvv2\) does not pass the type constraint because: '
	. '"\d+" is not a valid credit card security code'
	;

throws_ok
	{ Credit->new({ cvv2 => '48820' }) }
	qr/$error/,
	'caught csc too long ok'
	;

throws_ok
	{ Credit->new({ cvv2 => '42' }) }
	qr/$error/,
	'caught csc too short ok'
	;

done_testing;
