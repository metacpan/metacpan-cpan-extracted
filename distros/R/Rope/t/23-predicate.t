use Test::More;

{
	package Custom;

	use Rope;
	use Rope::Monkey;

	property one => (
		value => 2,
		writeable => 0,
		enumerable => 0,
		predicate => 1
	);

	property two => (
		value => 2,
		writeable => 0,
		enumerable => 0,
		predicate => 'we_have_two'
	);

	property three => (
		value => 2,
		writeable => 0,
		enumerable => 0,
		predicate => sub { return 1; }
	);

	property four => (
		value => 2,
		predicate => {
			value => sub { return 0; },
			writeable => 1
		}
	);

	monkey;

	1;
}

{
	package Extendings;

	use Rope;
	extends 'Custom';
}


my $k = Custom->new();

is($k->one, 2);

is($k->has_one, 1);

is($k->we_have_two, 1);

is($k->has_three, 1);

is($k->has_four, 0);

$k->has_four = sub { return 1 };

is($k->has_four, 1);

$k = Extendings->new();

is($k->one, 2);

is($k->has_one, 1);

is($k->we_have_two, 1);

is($k->has_three, 1);

is($k->has_four, 0);

$k->has_four = sub { return 1 };

is($k->has_four, 1);

ok(1);

done_testing();
