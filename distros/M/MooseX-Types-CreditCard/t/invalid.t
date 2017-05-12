#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use Test::Exception;

{
	package Credit;
	use Moose;
	use MooseX::Types::CreditCard qw( CardNumber );

	has card => (
		isa => CardNumber,
		is  => 'ro',
	);

	__PACKAGE__->meta->make_immutable;
}

my $error
	= 'Attribute \(card\) does not pass the type constraint because: '
	. '"4111111111111110" is not a valid credit card number'
	;

throws_ok
	{ Credit->new({ card => '4111111111111110' }) }
	qr/$error/,
	'caught invalid card ok'
	;

done_testing;
