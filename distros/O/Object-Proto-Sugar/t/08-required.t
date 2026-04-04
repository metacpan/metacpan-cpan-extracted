use Test::More;

{
	package Test;

	use Object::Proto::Sugar;

	our $trigger;
		
	has one => (
	  is  => 'rw',
	  isa => 'Any',
	  required => 1
	);

	1;
}

package main;

my $test = eval {
	new Test;
};

like($@, qr/required/, 'one is required and is not set');

my $okay = new Test 100;

is($okay->one, 100, 'setting a required attr is okay');

eval {
	$okay->one(undef);
};
like($@, qr/required/, 'one is required cannot set to undef');

done_testing();
