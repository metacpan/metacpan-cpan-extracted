use 5.008;
use strict;
use warnings;
use Test::More;
use Test::Requires 'Sub::MultiMethod';

use Types::Standard -types;

use MooX::Press (
	prefix => 'My',
	class => [
		'Class' => {
			with => [qw/ RoleA RoleB /],
			multimethod => [
				'foo' => {
					signature  => [ HashRef ],
					code       => sub { return "C" },
				},
			],
		},
	],
	role => [
		'RoleA' => {
			multimethod => [
				'foo' => {
					signature  => [ HashRef ],
					code       => sub { return "A" },
					alias      => "foo_a",
				},
			],
		},
		'RoleB' => {
			multimethod => [
				'foo' => {
					signature  => [ 'ArrayRef' ],
					code       => sub { return "B" },
				},
			],
		},
	],
);

my $obj = My::Class->new;

is( $obj->foo_a({}), 'A' );
is( $obj->foo([]), 'B' );
is( $obj->foo({}), 'C' );

done_testing;
