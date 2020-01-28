use v5.12;
use strict;
use warnings;

package My::RoleA {
	use Moo::Role;
	use Sub::MultiMethod -role, qw(multimethod);
	use Types::Standard -types;
	
	multimethod foo => (
		signature  => [ HashRef ],
		code       => sub { return "A" },
		alias      => "foo_a",
	);
}

package My::RoleB {
	use Moo::Role;
	use Sub::MultiMethod -role, qw(multimethod);
	use Types::Standard -types;
	
	multimethod foo => (
		signature  => [ ArrayRef ],
		code       => sub { return "B" },
	);
}

package My::Class {
	use Moo;
	use Sub::MultiMethod qw(multimethod multimethods_from_roles);
	use Types::Standard -types;
	
	with qw( My::RoleA My::RoleB );
	
	multimethods_from_roles qw( My::RoleA My::RoleB );
	
	multimethod foo => (
		signature  => [ HashRef ],
		code       => sub { return "C" },
	);
}

my $obj = My::Class->new;

say $obj->foo_a( {} );  # A
say $obj->foo( [] );    # B
say $obj->foo( {} );    # C
