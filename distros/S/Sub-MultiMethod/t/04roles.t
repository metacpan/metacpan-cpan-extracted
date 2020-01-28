use 5.008;
use strict;
use warnings;
use Test::More;

package My::RoleA; {
	use Role::Tiny;
	use Sub::MultiMethod -role, qw(multimethod);
	use Types::Standard -types;
	
	multimethod foo => (
		signature  => [ HashRef ],
		code       => sub { return "A" },
		alias      => "foo_a",
	);
}

package My::RoleB; {
	use Role::Tiny;
	use Sub::MultiMethod -role, qw(multimethod);
	use Types::Standard -types;
	
	multimethod foo => (
		signature  => [ ArrayRef ],
		code       => sub { return "B" },
	);
}

package My::Class; {
	use Class::Tiny;
	use Role::Tiny::With;
	use Sub::MultiMethod qw(multimethod multimethods_from_roles);
	use Types::Standard -types;
	
	with qw( My::RoleA My::RoleB );
	
	multimethods_from_roles qw( My::RoleA My::RoleB );
	
	multimethod foo => (
		signature  => [ HashRef ],
		code       => sub { return "C" },
	);
}

package main;

my $obj = My::Class->new;

is( $obj->foo_a({}), 'A' );
is( $obj->foo([]), 'B' );
is( $obj->foo({}), 'C' );

done_testing;
