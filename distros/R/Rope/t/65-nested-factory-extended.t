use Test::More;

use Rope (no_import => 1);

# from_nested_data with arrays containing hashes
my $obj = Rope->from_nested_data({
	name => 'root',
	items => [
		{ label => 'first', value => 1 },
		{ label => 'second', value => 2 },
	],
	meta => {
		nested => {
			deep => 'value'
		}
	}
});

is($obj->{name}, 'root', 'top-level string property');
is(ref $obj->{items}, 'ARRAY', 'array property preserved');
is($obj->{items}->[0]->{label}, 'first', 'nested hash in array converted to object');
is($obj->{items}->[0]->{value}, 1, 'nested object has correct value');
is($obj->{items}->[1]->{label}, 'second', 'second nested object');
is($obj->{meta}->{nested}->{deep}, 'value', 'deeply nested data accessible');

# from_nested_array with nested arrays
my $obj2 = Rope->from_nested_array([
	name => 'array_root',
	child => [
		x => 10,
		y => 20,
	],
]);

is($obj2->{name}, 'array_root', 'top-level from nested array');
is($obj2->{child}->{x}, 10, 'nested array converted to object');
is($obj2->{child}->{y}, 20, 'nested object values correct');

# from_data basic
my $obj3 = Rope->from_data({ a => 1, b => 'two' });
is($obj3->{a}, 1, 'from_data integer value');
is($obj3->{b}, 'two', 'from_data string value');

# from_data properties are writeable
$obj3->{a} = 100;
is($obj3->{a}, 100, 'from_data properties are writeable');

# from_array basic
my $obj4 = Rope->from_array([p => 1, q => 2, r => 3]);
is($obj4->{p}, 1, 'from_array first value');
is($obj4->{q}, 2, 'from_array second value');
is($obj4->{r}, 3, 'from_array third value');

# from_array properties are writeable
$obj4->{p} = 'updated';
is($obj4->{p}, 'updated', 'from_array properties are writeable');

# from_nested_array with ROPE_scope marker to preserve arrays
my $obj5 = Rope->from_nested_array([
	name => 'scoped',
	list => [1, 2, 3, { ROPE_scope => 'ARRAY' }],
]);

is($obj5->{name}, 'scoped', 'name with ROPE_scope');
is(ref $obj5->{list}, 'ARRAY', 'ROPE_scope preserves array');
is_deeply($obj5->{list}, [1, 2, 3], 'array values preserved without scope marker');

done_testing();
