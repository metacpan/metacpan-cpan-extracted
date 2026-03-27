use Test::More;

use Types::Standard qw/Int Str ArrayRef/;

{
	package TypeErrors;

	use Rope;
	use Types::Standard qw/Int Str ArrayRef/;

	property count => (
		type => Int,
		value => 0,
		initable => 1,
		writeable => 1,
		enumerable => 1,
	);

	property label => (
		type => Str,
		value => 'default',
		initable => 1,
		writeable => 1,
		enumerable => 1,
	);

	property items => (
		type => ArrayRef,
		value => [],
		initable => 1,
		writeable => 1,
		enumerable => 1,
	);

	1;
}

# valid construction
my $obj = TypeErrors->new(count => 5, label => 'test', items => [1, 2]);
is($obj->{count}, 5);
is($obj->{label}, 'test');
is_deeply($obj->{items}, [1, 2]);

# type error on set
eval { $obj->{count} = 'not a number' };
like($@, qr/failed type validation/, 'setting wrong type on writeable property fails');

# type error on init
eval { TypeErrors->new(count => 'bad') };
like($@, qr/failed type validation/, 'wrong type at init fails validation');

# valid type updates
$obj->{count} = 42;
is($obj->{count}, 42, 'valid type update succeeds');

$obj->{label} = 'updated';
is($obj->{label}, 'updated', 'valid string update succeeds');

$obj->{items} = [3, 4, 5];
is_deeply($obj->{items}, [3, 4, 5], 'valid arrayref update succeeds');

done_testing();
