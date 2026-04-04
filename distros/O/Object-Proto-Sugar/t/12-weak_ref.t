use Test::More;

{
	package Test;

	use Object::Proto::Sugar;

	has strong => (
	  is  => 'rw',
	  isa => 'Any',
	);

	has weak => (
	  is       => 'rw',
	  isa      => 'Any',
	  weak_ref => 1,
	);

	1;
}

package main;

my $test = new Test;

# weak ref becomes undef when the only strong ref goes away
{
	my $obj = { value => 42 };
	$test->weak($obj);
	is($test->weak, $obj, 'weak ref holds object while strong ref exists');
}
is($test->weak, undef, 'weak ref is undef after object goes out of scope');

# strong ref keeps the object alive
{
	my $obj = { value => 99 };
	$test->strong($obj);
}
isnt($test->strong, undef, 'strong ref keeps object alive after lexical goes out of scope');

done_testing();
