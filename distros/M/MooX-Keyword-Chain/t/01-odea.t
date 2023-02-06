use Test::More;

{
	package MyChains;
	
	use Moo;
	use MooX::Keyword extends => '+Chain';

	has data => (
		is => 'ro',
		default => sub { { } }
	);

	chain thing => 'setup' => sub {
		$_[0]->data->{one} = 'hello';
	};

	chain thing => 'extend' => sub {
		$_[0]->data->{two} = 'goodbye';
	};

	chain thing => 'finalize' => sub {
		$_[0]->data->{three} = 'breakdown';
	};
}

my $chain = MyChains->new();

$chain->thing();

is_deeply( 
	$chain->data,
	{
		one => 'hello',
		two => 'goodbye',
		three => 'breakdown'
	}
);

done_testing();
