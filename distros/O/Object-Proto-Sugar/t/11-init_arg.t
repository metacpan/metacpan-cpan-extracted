use Test::More;

{
	package Test;

	use Object::Proto::Sugar;

	our $trigger;
		
	has one => (
	  is  => 'rw',
	  isa => 'Any',
	  init_arg => '_one'
	);

	has two => (
	  is  => 'rw',
	  isa => 'Any',
	  arg => '_two_two',
	);

	1;
}

package main;

my $test = new Test _one => 123, _two_two => 234;
is_deeply($test, [undef, 123, 234], 'Default sets slot to 555');

is($test->one, 123, 'call one to get 123');
is($test->two, 234, 'call two to get 234');

done_testing();
