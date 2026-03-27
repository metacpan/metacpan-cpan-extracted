use Test::More;

{
	package Parent1;

	use Rope;

	prototyped (
		from_p1 => 'parent1',
	);

	function p1_method => sub {
		my ($self) = @_;
		return 'p1';
	};

	1;
}

{
	package Parent2;

	use Rope;

	prototyped (
		from_p2 => 'parent2',
	);

	function p2_method => sub {
		my ($self) = @_;
		return 'p2';
	};

	1;
}

{
	package MultiChild;

	use Rope;

	extends 'Parent1';
	extends 'Parent2';

	prototyped (
		own => 'child',
	);

	1;
}

my $obj = MultiChild->new();
is($obj->{from_p1}, 'parent1', 'inherits from first parent');
is($obj->{from_p2}, 'parent2', 'inherits from second parent');
is($obj->{own}, 'child', 'has own property');
is($obj->{p1_method}(), 'p1', 'inherited method from parent1');
is($obj->{p2_method}(), 'p2', 'inherited method from parent2');

# isa checks
ok($obj->isa('Parent1'), 'isa Parent1');
ok($obj->isa('Parent2'), 'isa Parent2');

# Multiple roles
{
	package Role1;

	use Rope;
	use Rope::Role;

	property r1 => (
		value => 'role1',
		enumerable => 1,
		writeable => 0,
	);

	1;
}

{
	package Role2;

	use Rope;
	use Rope::Role;

	property r2 => (
		value => 'role2',
		enumerable => 1,
		writeable => 0,
	);

	1;
}

{
	package MultiRole;

	use Rope;

	with 'Role1';
	with 'Role2';

	prototyped (
		own => 'mine',
	);

	1;
}

my $obj2 = MultiRole->new();
is($obj2->{r1}, 'role1', 'has role1 property');
is($obj2->{r2}, 'role2', 'has role2 property');
is($obj2->{own}, 'mine', 'has own property');

done_testing();
