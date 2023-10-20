use Test::More;

{
	package Custom;

	use Rope;
	use Rope::Type qw/int bool str hash array hash code file obj/;

	int one => 1;

	int two => (
		value => 2,
		writeable => 0,
		enumerable => 0,
	);

	property three => (
		type => int,
		value => 3,
		writeable => 0,
		enumerable => 0,
	);

	property four => (
		type => sub { $_[0] =~ m/^\d+$/ ? $_[0] : die "Invalid integer" },
		value => 4,
		writeable => 1,
		configurable => 1,
		enumerable => 0,
	);

	bool five => 0;

	str six;

	hash seven;

	array eight => [qw/1 2 3/];


	function add => sub {
		my ($self, $num) = @_;
		$self->{one} += int->($num);
	};

	1;
}

my $k = Custom->new(
	six => 'testing',
	seven => { one => 1 }
);

is($k->{one}, 1);
is($k->{two}, 2);
is($k->{three}, 3);
is($k->{four}, 4);

$k->{one} = 5;
$k->{four} = 6;

is($k->{one}, 5);

eval { $k->{one} = 'test' };
like($@, qr/Cannot set property \(one\) in object \(Custom\)/);
is($k->{four}, 6);

is($k->{six}, 'testing');
is_deeply($k->{seven}, { one => 1 });
is_deeply($k->{eight}, [qw/1 2 3/]);

$k->{add}(7);
is($k->{one}, 12);


done_testing();
