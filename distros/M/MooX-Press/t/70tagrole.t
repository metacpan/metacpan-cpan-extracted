use strict;
use warnings;
use Test::More;

use MooX::Press (
	prefix     => 'Local::App',
	class      => [
		'Foo' => [ with => 'Quux?' ],
		'Bar' => [ with => 'Quux?' ],
	],
);

use Local::App::Types -types;

isa_ok( Quux, 'Type::Tiny::Role' );

done_testing;
