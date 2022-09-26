use strict;
use warnings;
use Test::More;
use Test::Requires 'MRO::Compat';
use Test::Requires '5.010';

{
	package Class::DFS::A;
	use Class::Tiny;
	use Types::Standard -types;
	use Sub::MultiMethod -all;
	
	multimethod foo => (
		_id        => __PACKAGE__,
		positional => [ Int ],
		code       => sub { return __PACKAGE__ },
	);
}

{
	package Class::DFS::B;
	use parent -norequire, qw( Class::DFS::A );
	use Class::Tiny;
}

{
	package Class::DFS::C;
	use parent -norequire, qw( Class::DFS::A );
	use Class::Tiny;
	use Types::Standard -types;
	use Sub::MultiMethod -all;
	
	multimethod foo => (
		_id        => __PACKAGE__,
		positional => [ Int ],
		code       => sub { return __PACKAGE__ },
	);
}

{
	package Class::DFS::D;
	use parent -norequire, qw( Class::DFS::B Class::DFS::C );
	use Class::Tiny;
}

is( Class::DFS::D->foo(1), 'Class::DFS::A', 'depth-first search; class method' );
is( Class::DFS::D->new->foo(1), 'Class::DFS::A', 'depth-first search; object method' );
is( Class::DFS::D->can('foo')->(undef, 1), 'Class::DFS::A', 'depth-first search; non-method call' );

{
	package Class::C3::A;
	use mro 'c3';
	use Class::Tiny;
	use Types::Standard -types;
	use Sub::MultiMethod -all;
	
	multimethod foo => (
		_id        => __PACKAGE__,
		positional => [ Int ],
		code       => sub { return __PACKAGE__ },
	);
}

{
	package Class::C3::B;
	use mro 'c3';
	use parent -norequire, qw( Class::C3::A );
	use Class::Tiny;
}

{
	package Class::C3::C;
	use mro 'c3';
	use parent -norequire, qw( Class::C3::A );
	use Class::Tiny;
	use Types::Standard -types;
	use Sub::MultiMethod -all;
	
	multimethod foo => (
		_id        => __PACKAGE__,
		positional => [ Int ],
		code       => sub { return __PACKAGE__ },
	);
}

{
	package Class::C3::D;
	use mro 'c3';
	use parent -norequire, qw( Class::C3::B Class::C3::C );
	use Class::Tiny;
}

is( Class::C3::D->foo(1), 'Class::C3::C', 'C3; class method' );
is( Class::C3::D->new->foo(1), 'Class::C3::C', 'C3; object method' );
is( Class::C3::D->can('foo')->(undef, 1), 'Class::C3::C', 'C3; non-method call' );

done_testing;

