use Test::More;

{
	package Test;

	use Object::Proto::Sugar;

		
	has one => (
	  is  => 'ro',
	  isa => 'Int',
	  builder => sub { 100 },
	  predicate => 1
	);

	has two => (
	  is  => 'ro',
	  isa => 'Num',
	  builder => 1,
	  predicate => 'defined_two'
	);

	sub _build_two {
		1.5
	}

	has three => (
	   is => 'ro',
	   predicate => 1
	);

	1;
}

package main;

my $test = new Test;

is($test->has_one, 1, 'one - Int');
is($test->defined_two, 1, 'two - Num');
is($test->has_three, '', 'three is not set');

done_testing();
