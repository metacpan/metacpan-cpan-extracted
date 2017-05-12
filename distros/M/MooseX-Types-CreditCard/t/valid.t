#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

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

my $c1 = Credit->new({ card => '4111111111111111' });

is( $c1->card, '4111111111111111', 'check card number returns' );

done_testing;
