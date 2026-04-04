use Test::More;

{
	package Test;

	use Object::Proto::Sugar;
		
	has one => (
	  is  => 'ro',
	  isa => 'Int',
	  builder => sub { 100 },
	);

	has two => (
	  is  => 'ro',
	  isa => 'Num',
	  builder => 1
	);

	sub _build_two {
		1.5
	}

	has three => (
	  is  => 'ro',
	  isa => 'Str',
	  builder => sub { "This is a test" }
	);
	
	has four => (
	  is => 'rw',
	  isa => 'ArrayRef',
	  builder => sub { [] }
	);

	has five => (
	  is => 'rw',
	  isa => 'HashRef',
	  builder => sub { {} }
	);

        has six => (
	  is => 'rw',
	  isa => 'Any',
	  builder => sub { undef }
	);

	has seven => (
	  is => 'rw',
	  isa => 'HashRef',
	  builder => 1,
	);

	sub _build_seven {
		 { a => 1, b => 2, c => 3 } 
	} 

	1;
}

package main;

my $test = new Test;

is($test->one, 100, 'one - Int');
is($test->two, 1.5, 'two - Num');
is($test->three, 'This is a test', 'three - Str');
is_deeply($test->four, [], 'four - ArrayRef');
is_deeply($test->five, {}, 'five - HashRef');
is($test->six, undef, 'six - Any (undef)');
is_deeply($test->seven, { a => 1, b => 2, c => 3 }, 'seven - HashRef builder');


ok($test->four([qw/1 2 3/]), 'set four to 1, 2, 3');
is_deeply($test->four, [qw/1 2 3/], 'four is an arrayref 1, 2, 3');




done_testing();
