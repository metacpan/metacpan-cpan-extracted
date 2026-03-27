use Test::More;

{
	package CoreOps;

	use Rope;

	prototyped (
		name => 'test',
		count => 0,
	);

	property hidden => (
		value => 'secret',
		writeable => 0,
		enumerable => 0,
	);

	property configurable_prop => (
		value => 'hello',
		configurable => 1,
		enumerable => 1,
	);

	property writeable_prop => (
		value => 100,
		writeable => 1,
		enumerable => 1,
	);

	property deletable => (
		value => 'delete me',
		writeable => 1,
		enumerable => 1,
	);

	property with_delete_trigger => (
		value => 'triggered',
		writeable => 1,
		enumerable => 1,
		delete_trigger => sub {
			my ($self, $val) = @_;
			$self->{count}++;
		}
	);

	function do_something => sub {
		my ($self) = @_;
		return 'done';
	};

	1;
}

my $k = CoreOps->new();

# EXISTS
ok(exists $k->{name}, 'EXISTS returns true for existing property');
ok(exists $k->{hidden}, 'EXISTS returns true for non-enumerable property');
ok(!exists $k->{nonexistent}, 'EXISTS returns false for missing property');

# SCALAR
my $count = scalar %{$k};
ok($count > 0, 'SCALAR returns property count');

# configurable - same type allowed
$k->{configurable_prop} = 'world';
is($k->{configurable_prop}, 'world', 'configurable allows same type update');

# configurable - different type rejected
eval {
	$k->{configurable_prop} = sub { 1 };
};
like($@, qr/Cannot change Object \(CoreOps\) property \(configurable_prop\) type/,
	'configurable rejects different type');

# DELETE a writeable property
is($k->{deletable}, 'delete me');
delete $k->{deletable};
ok(!defined $k->{deletable}, 'property deleted successfully');

# DELETE triggers delete_trigger
is($k->{count}, 0, 'count starts at 0');
delete $k->{with_delete_trigger};
is($k->{count}, 1, 'delete_trigger incremented count');

# DELETE on non-writeable property should not delete
is($k->{hidden}, 'secret');
my $result = delete $k->{hidden};
is($result, undef, 'cannot delete non-writeable property');
is($k->{hidden}, 'secret', 'non-writeable property still exists');

# can method
ok($k->can('do_something'), 'can returns true for existing function');
ok($k->can('name'), 'can returns true for existing property');

# destroy
$k->destroy();
ok(1, 'destroy completed without error');

done_testing();
