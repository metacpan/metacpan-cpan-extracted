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

	chain add => 'politicians' => sub {
  		my $self = shift;
		push @{ $self->boat }, 'leadership';
		return @_;
	};
 
	chain add => 'reporters' => sub {
		push @{ $_[0]->boat }, 'propaganda';
		return;
	};
	 
	chain add => 'bankers' => sub {
		push @{ $_[0]->boat }, 'finance';
		return;
	};

	factory add => (
		[Str] => sub {
			push @{$_[0]->boat}, 'string';
			return $_[0]->boat;
		},
		[Str, Str] => sub { 
			push @{$_[0]->boat}, 'string string';
			return $_[0]->boat;
		}
	);

	1;
}

{
	package Extendings;

	use Rope;
	extends 'Custom';
}

my $c = Custom->new();

is_deeply($c->add('one'), ['leadership', 'propaganda', 'finance', 'string']);

is_deeply($c->boat, ['leadership', 'propaganda', 'finance', 'string']);

$c = Extendings->new();

is_deeply($c->add('one', 'two'), ['leadership', 'propaganda', 'finance', 'string string']);

is_deeply($c->boat, ['leadership', 'propaganda', 'finance', 'string string']);

ok(1);

done_testing();
