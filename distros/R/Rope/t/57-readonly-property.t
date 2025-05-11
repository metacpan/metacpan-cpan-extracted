use Test::More;

{
	package Custom;

	use Rope;

	readonly one => { a => 1, b => 2, c => 3 };

	readonly three => [qw/one two three/];

	readonly four => "Hello World";

	function two => sub { 
		my ($self, $int) = @_;
		$self->{one}->{a} + $int;
	};

	1;
}

my $k = Custom->new();

eval {
	$k->{one}->{a} = 50;
};

like($@, qr/Modification of a read-only value attempted/);

is($k->{two}(10), 11);

is($k->{four}, 'Hello World');

eval {
	push @{ $k->{three} }, 555;
};

like($@, qr/Modification of a read-only value attempted/);

ok(1);

my $set = Custom->new( one => { a => 100, b => 200, c => 300 } );

is($set->{one}->{a}, 100);


done_testing();
