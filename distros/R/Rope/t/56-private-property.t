use Test::More;

{
	package Custom;

	use Rope;

	private one => 2;

	function two => sub { 
		my ($self, $int) = @_;
		$self->{one} + $int;
	};

	1;
}

my $k = Custom->new();

eval {
	$k->{one} = 50;
};

like($@, qr/Cannot access Object \(Custom\) property \(one\) as it is private/);

is($k->{two}(10), 12);

ok(1);

done_testing();
