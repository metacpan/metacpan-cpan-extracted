#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

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

my $c = Credit->new({ cvv2 => '123' });

is( $c->cvv2 , '123', 'check csc returns' );

done_testing;
