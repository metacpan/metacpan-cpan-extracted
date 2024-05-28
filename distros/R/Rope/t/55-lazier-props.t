use Test::More;

{
	package Custom;

	use Rope;
	use Rope::Lazier;
	use Types::Standard qw/Int/;

	props (
		one => {
			v(1), w, e, t(Int)
		}
	);

	prop two => ( v(2) );

	fun three => sub { 
		my ($self, $int) = @_;
		$self->{two} + $int;
	};

	pro (
		four => 4,
		five => 5
	);

	1;
}

my $k = Custom->new();

is($k->{one}, 1);
is($k->{two}, 2);

my @keys = keys %{$k};

is_deeply(\@keys, [qw/one four five/]);

$k->{one} = 10;
is($k->{one}, 10);

eval {
	$k->{two} = 50;
};

like($@, qr/Cannot set Object \(Custom\) property \(two\) it is only readable/);

is($k->{three}(10), 12);

is($k->{four}, 4);
is($k->{five}, 5);


ok(1);

done_testing();
