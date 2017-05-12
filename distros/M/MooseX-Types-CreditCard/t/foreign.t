#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

{
	package Credit;
	use Moose;
	use MooseX::Types::CreditCard qw( CardNumber );

	has card => (
		isa    => CardNumber,
		is     => 'ro',
		coerce => 1,
	);

	__PACKAGE__->meta->make_immutable;
}

my $c = Credit->new({ card => '6304 9850 2809 0561 515' });

is( $c->card, '6304985028090561515', 'check card number returns' );

done_testing;
