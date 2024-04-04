use Test::More;

{
	package Custom;

	use Rope;
	use Rope::Autoload;
	use Rope::Factory qw/Str/;
	use Rope::Chain;

	prototyped (
		boat => []
	);

	factory add => (
		[Str] => sub {
			push @{$_[0]->boat}, 'string';
		},
		[Str, Str] => sub { 
			push @{$_[0]->boat}, 'string string';
		}
	);


	chain add => 'politicians' => sub {
  	      push @{ $_[0]->boat }, 'leadership';
	};
 
	chain add => 'reporters' => sub {
		push @{ $_[0]->boat }, 'propaganda';
	};
	 
	chain add => 'bankers' => sub {
		push @{ $_[0]->boat }, 'finance';
		return $_[0]->boat;
	};

	1;
}

{
	package Extendings;

	use Rope;
	extends 'Custom';
}

my $c = Custom->new();

is_deeply($c->add('one'), ['string', 'leadership', 'propaganda', 'finance']);

is_deeply($c->boat, ['string', 'leadership', 'propaganda', 'finance']);

$c = Extendings->new();

is_deeply($c->add('one', 'two'), ['string string', 'leadership', 'propaganda', 'finance']);

is_deeply($c->boat, ['string string', 'leadership', 'propaganda', 'finance']);

ok(1);

done_testing();
