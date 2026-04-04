use Test::More;

{
	package Test;

	use Object::Proto::Sugar;

	our $trigger;
	BEGIN { $trigger =  sub { $_[0]->one($_[1] + 2); $_[1]; } };
		
	has one => (
	  is  => 'rw',
	);

	has two => (
	  is  => 'rw',
	  trigger => $trigger,
	);

	has three => (
	  is  => 'rw',
	  trigger => $trigger 
	);

	1;
}

package main;

my $test = new Test 6, 1, 5;

is($test->one, 7, 'default set by last param set "three"');

ok($test->three(3), 'set three to 3 to set one to 5');
is($test->one, 5, 'one is 5');
is($test->three, 3, 'three is 3');

ok($test->two(2), 'set two to 2 to set one to 4');
is($test->one, 4, 'one is 4');
is($test->two, 2, 'two is 2');





done_testing();
