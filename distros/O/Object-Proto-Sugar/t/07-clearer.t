use Test::More;

{
	package Test;

	use Object::Proto::Sugar;
		
	has one => (
	  is  => 'rw',
	  isa => 'Int',
	  builder => sub { 100 },
	  clearer => 1
	);

	has two => (
	  is  => 'ro',
	  isa => 'Num',
	  builder => 1,
	  clearer => 'clearing_two'
	);

	sub _build_two {
		1.5
	}

	has three => (
	   is => 'rw',
	   clearer => 1
	);

	1;
}

package main;

my $test = new Test;

is($test->one, 100, 'default for one is 100');
is($test->one(500), 500, 'Set one to 500');
is($test->one, 500, 'one is 500');
ok($test->clear_one, 'clear one');
is($test->one, undef, 'one will now be undef');

is($test->three, undef, 'undefined three');
is($test->three(500), 500, 'set three to 500');
ok($test->clear_three, 'Okay clear three');
is($test->three, undef, 'Three is undef again');

done_testing();
