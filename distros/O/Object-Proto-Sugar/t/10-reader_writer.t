use Test::More;

{
	package Test;

	use Object::Proto::Sugar;

	our $trigger;
		
	has one => (
	  is  => 'rw',
	  isa => 'Any',
	  reader => 1,
	  writer =>  1,
	  default => sub { 555 }
	);

	has two => (
	  is  => 'rw',
	  isa => 'Any',
	  lazy => 1,
	  reader => 'get_z',
	  writer =>  'set_z',
	  default => sub { 'testing' }
	);


	1;
}

package main;

my $test = new Test;
is_deeply($test, [undef, 555, undef], 'Default sets slot to 555');

is($test->one, 555, 'call one to get 555');
is($test->get_one, 555, 'reader return 555 also');
is($test->set_one(111), 111, 'setter sets 111');
is($test->get_one, 111, 'reader return 111');

is($test->get_z, 'testing', 'get_z returns testing');
is($test->set_z('okay'), 'okay', 'set_z to okay returns okay');
is($test->get_z, 'okay', 'get_z returns okay');

done_testing();
