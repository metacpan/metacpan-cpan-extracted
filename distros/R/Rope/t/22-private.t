use Test::More;

{
	package Custom;

	use Rope;
	use Rope::Monkey;

	prototyped (
		one => 1
	);

	property two => (
		value => 2,
		writeable => 0,
		enumerable => 0,
		private => 1,
	);

	function three => sub { 
		my ($self, $int) = @_;
		$self->two + $int;
	};

	monkey;

	1;
}

{
	package Extendings;

	use Rope;
	extends 'Custom';
}


my $k = Custom->new();

is($k->one, 1);

eval {
	$k->two;
};

like($@, qr/Cannot access Object \(Custom\) property \(two\) as it is private/);

is($k->three(3), 5);

$k = Extendings->new();

is($k->one, 1);

eval {
	$k->two;
};

like($@, qr/Cannot access Object \(Extendings\) property \(two\) as it is private/);

is($k->three(3), 5);

ok(1);

done_testing();
