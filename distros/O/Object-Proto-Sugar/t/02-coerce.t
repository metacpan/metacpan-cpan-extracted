use Test::More;

{
	package Test;

	use Object::Proto::Sugar;

	our $coerce;
	BEGIN { $coerce =  sub { return $_[0] + 2 } };
		
	has one => (
	  is  => 'ro',
	  coerce => $coerce,
	);

	has two => (
	  is  => 'rw',
	  coerce => $coerce,
	);

	has three => (
	  is  => 'rw',
	  coerce => sub { $_[0] + 2 },
	);

	1;
}

package main;

my $test = new Test 10, 1, 5;

is($test->one, 12, '10 + 2 == 12');
is($test->two, 3, '1 + 2 == 3');
is($test->three, 7, '5 + 2 == 7');

is($test->two(6), 8, '6 + 2 == 8');

eval { $test->one(6) };
like($@, qr/readonly/, 'readonly');

done_testing();
