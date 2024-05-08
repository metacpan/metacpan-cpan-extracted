use Test::More;

{
	package Hospital::Attributes;

	use Rope;
	use Rope::Autoload;

	prototyped (
		one => undef,
		two => undef,
		three => undef
	);

	1;
}

{
	package Hospital;

	use Rope;
	use Rope::Autoload;

	property attributes => (
		enumerable => 0,
		writeable => 0,
		configurable => 0,
		initable => 1,
	);

	1;
}

my $h = Hospital->new(
	attributes => Hospital::Attributes->new(
		one => 1,
		two => 2,
		three => 3
	)
);

is($h->attributes->three, 3);

$h->attributes->three = 10;

is($h->attributes->three, 10);

done_testing();





