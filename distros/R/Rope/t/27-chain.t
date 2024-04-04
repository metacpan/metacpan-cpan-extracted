use Test::More;

{
	package Custom;

	use Rope;
	use Rope::Autoload;
	use Rope::Chain;

	prototyped (
		boat => []
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

is_deeply($c->add(), ['leadership', 'propaganda', 'finance']);

is_deeply($c->boat, ['leadership', 'propaganda', 'finance']);

$c = Extendings->new();

is_deeply($c->add(), ['leadership', 'propaganda', 'finance']);

is_deeply($c->boat, ['leadership', 'propaganda', 'finance']);

ok(1);

done_testing();
