use Test::More;

{
	package Test;

	use Object::Proto::Sugar;

	our $trigger;
		
	has one => (
	  is  => 'rw',
	  isa => 'Any',
	  lazy => 1,
	  default => sub { 555 }
	);

	1;
}

package main;

my $test = new Test;
is_deeply($test, [undef, undef], 'lazy so no values set yet');

is($test->one, 555, 'call one to get 555');

is_deeply($test, [undef, 555], 'lazy attribute loaded');

done_testing();
