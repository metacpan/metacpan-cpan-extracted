#!perl

use strict;
use warnings;

use Test::Most;


{
	package Test::One::PayProp::API::Public::Client::Response;

	use Mouse;

	foreach my $attr (
		[ 'is_active', 'Bool', 1 ],
		[ 'hashref', 'HashRef', { one => 'two' } ],
		[ 'arrayref', 'ArrayRef', [ qw/ one two / ] ],
	) {
		my ( $name, $type, $default ) = $attr->@*;

		has $name => (
			is => 'ro',
			isa => $type,
			lazy => 1,
			default => sub { $default },
		);
	}

	1;
}

{
	package Test::Two::PayProp::API::Public::Client::Response;

	use Mouse;
	with qw/ PayProp::API::Public::Client::Role::JSON /;

	foreach my $attr (
		[ 'is_active', 'Bool', 1 ],
		[ 'hashref', 'HashRef', { a => 1, b => [ qw/ a b c d / ] } ],
		[ 'arrayref', 'ArrayRef', [ z => { x => [ 1, 2, 3 ] } ] ],
		[ 'Object', 'Test::One::PayProp::API::Public::Client::Response', Test::One::PayProp::API::Public::Client::Response->new ]
	) {
		my ( $name, $type, $default ) = $attr->@*;

		has $name => (
			is => 'ro',
			isa => $type,
			lazy => 1,
			default => sub { $default },
		);
	}

	1;
}

use_ok('Test::Two::PayProp::API::Public::Client::Response');
isa_ok( my $JSON = Test::Two::PayProp::API::Public::Client::Response->new, 'Test::Two::PayProp::API::Public::Client::Response' );

subtest '->TO_JSON' => sub {

	cmp_deeply
		$JSON->TO_JSON,
		{
			Object => {
				is_active => 1,
				hashref => {
					one => 'two',
				},
				arrayref => [
					'one',
					'two',
				],
			},
			hashref => {
				a => 1,
				b => [
					'a',
					'b',
					'c',
					'd',
				],
			},
			is_active => 1,
			arrayref => [
				'z',
				{
					x => [
						1,
						2,
						3,
					],
				},
			],
		},
	;
};

done_testing;
