use Test::More;

use Rope (no_import => 1);

{
	package MetaTest;

	use Rope;

	prototyped (
		alpha => 1,
		beta => 2,
	);

	property gamma => (
		value => 3,
		writeable => 1,
		enumerable => 1,
	);

	1;
}

# get_meta
my $meta = Rope->get_meta('MetaTest');
ok($meta, 'get_meta returns meta');
is($meta->{name}, 'MetaTest', 'meta has correct name');
ok($meta->{properties}{alpha}, 'meta contains alpha property');
ok($meta->{properties}{beta}, 'meta contains beta property');
ok($meta->{properties}{gamma}, 'meta contains gamma property');

# set_property
Rope->set_property('MetaTest', 'delta', {
	value => 4,
	writeable => 1,
	enumerable => 1,
	initable => 1,
	configurable => 1,
	index => 10,
});

my $obj = MetaTest->new();
is($obj->{delta}, 4, 'set_property adds new property');

# clear_property
Rope->clear_property('MetaTest', 'delta');
my $meta2 = Rope->get_meta('MetaTest');
ok(!$meta2->{properties}{delta}, 'clear_property removes property');

# clear_meta
Rope->clear_meta('MetaTest');
my $meta3 = Rope->get_meta('MetaTest');
is($meta3->{name}, 'MetaTest', 'clear_meta preserves name');
is(scalar keys %{$meta3->{properties}}, 0, 'clear_meta removes all properties');
is($meta3->{locked}, 0, 'clear_meta resets locked');

done_testing();
