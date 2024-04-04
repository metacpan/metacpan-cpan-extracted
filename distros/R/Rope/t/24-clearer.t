use Test::More;

{
	package Custom;

	use Rope;
	use Rope::Monkey;

	property one => (
		value => 2,
		writeable => 1,
		enumerable => 0,
		clearer => 1
	);

	property two => (
		value => 2,
		writeable => 1,
		enumerable => 0,
		clearer => 'we_clear_two'
	);

	property three => (
		value => 2,
		writeable => 1,
		enumerable => 0,
		clearer => sub { $_[0]->{$_[1]} = undef; }
	);

	property four => (
		value => 2,
		writeable => 1,
		clearer => {
			value => sub { $_[0]->{$_[1]} = undef; },
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

$k->clear_one;

is($k->one, undef);

$k->we_clear_two;

is($k->two, undef);

$k->clear_three;

is($k->three, undef);

$k->clear_four;

is($k->four, undef);

$k = Extendings->new();

is($k->one, 2);

$k->clear_one;

is($k->one, undef);

$k->we_clear_two;

is($k->two, undef);

$k->clear_three;

is($k->three, undef);

$k->clear_four;

is($k->four, undef);




ok(1);

done_testing();
