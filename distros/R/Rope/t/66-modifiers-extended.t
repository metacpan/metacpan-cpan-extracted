use Test::More;

{
	package ModBase;

	use Rope;
	use Rope::Autoload;

	property value => (
		value => 0,
		configurable => 1,
		enumerable => 1,
	);

	function compute => sub {
		my ($self, $x) = @_;
		return $x;
	};

	1;
}

{
	package ModChild;

	use Rope;
	extends 'ModBase';

	# multiple before modifiers
	before compute => sub {
		my ($self, $x) = @_;
		return $x + 1;
	};

	before compute => sub {
		my ($self, $x) = @_;
		return $x * 2;
	};

	# multiple after modifiers
	after compute => sub {
		my ($self, $result) = @_;
		return $result + 100;
	};

	after compute => sub {
		my ($self, $result) = @_;
		return $result * 3;
	};

	1;
}

my $base = ModBase->new();
is($base->{compute}(5), 5, 'base compute returns input');

my $child = ModChild->new();
my $result = $child->{compute}(5);
# before: 5 + 1 = 6, then 6 * 2 = 12
# compute(12) = 12
# after: 12 + 100 = 112, then 112 * 3 = 336
is($result, 336, 'multiple before and after modifiers chain correctly');

# requires failure test
{
	package RequiresRole;

	use Rope;
	use Rope::Role;

	requires qw/must_have/;

	property role_prop => (
		value => 'from_role',
		enumerable => 1,
		writeable => 0,
	);

	1;
}

{
	package HasRequired;

	use Rope;

	property must_have => (
		value => 'present',
		enumerable => 1,
		writeable => 0,
	);

	with 'RequiresRole';

	1;
}

my $obj = HasRequired->new();
is($obj->{must_have}, 'present', 'required property exists');
is($obj->{role_prop}, 'from_role', 'role property included');

# requires failure when property is missing
{
	package MissingRequired;

	use Rope;

	with 'RequiresRole';

	1;
}

eval {
	MissingRequired->new();
};
like($@, qr/requires property must_have/, 'requires fails when property missing');

done_testing();
