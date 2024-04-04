use Test::More;

{
	package Custom;

	use Rope;

	property one => (
		initable => 1,
		value => 'kaput',
		writeable => 0,
		enumerable => 1,
	);

	property two => (
		value => 2,
		writeable => 0,
		enumerable => 0,
	);

	1;
}


my $k = Custom->new();

is($k->{one}, 'kaput');
is($k->{two}, 2);

ok(1);

done_testing();
