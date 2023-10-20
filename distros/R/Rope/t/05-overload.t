use Test::More;

{
	package Custom;

	use Rope;
	use Rope::Autoload;

	prototyped (
		one => 1
	);

	property two => (
		value => 2,
		writeable => 0,
		enumerable => 0,
	);

	function three => sub { 
		my ($self, $int) = @_;
		$self->{two} + $int;
	};

	1;
}


my $k = Custom->new();

is($k->one, 1);
is($k->two, 2);

my @keys = keys %{$k};

is_deeply(\@keys, [qw/one/]);

$k->one = 10;

is($k->one, 10);

eval {
	$k->two = 50;
};

like($@, qr/Cannot set Object \(Custom\) property \(two\) it is only readable/);

is($k->{three}(10), 12);

ok(1);

done_testing();
