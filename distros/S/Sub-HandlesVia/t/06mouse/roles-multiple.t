use strict;
use warnings;
use Test::More skip_all => 'TODO (issue #9)';
use Test::Fatal;
{ package Local::Dummy1; use Test::Requires 'Mouse' };

{
	package TestRole1;
	use Mouse::Role;
}

{
	package TestRole2;
	use Mouse::Role;
	use Types::Standard qw(ArrayRef);
	use Sub::HandlesVia;

	has test => (
		is          => 'ro',
		isa         => ArrayRef,
		default     => sub { [] },
		handles_via => 'Array',
		handles     => { all_test => 'all' },
	);
}

{
	package TestClass;
	use Mouse;
	with qw(
		TestRole1
		TestRole2
	);
	__PACKAGE__->meta->make_immutable;
}

my $obj = TestClass->new( test => [ 1, 2 ] );
is_deeply( [ $obj->all_test ], [ 1, 2 ] );

done_testing;
