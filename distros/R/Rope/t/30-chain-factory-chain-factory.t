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
			return ('one', 'two');
		},
		[Str, Str] => sub { 
			push @{$_[0]->boat}, 'string string';
			return ('one');
		}
	);

	chain add => 'slaves' => sub {
		push @{ $_[0]->boat }, 'people';
		return;
	};

	factory add => 1 => (
		[Str] => sub {
			push @{$_[0]->boat}, 'string';
			return ('one', 'two');
		},
		[Str, Str] => sub { 
			push @{$_[0]->boat}, 'string string';
			return ('one');
		}
	);

	factory add => 2 => (
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

	use Rope::Factory qw/ArrayRef/;

	factory add => 3 => (
		[ArrayRef] => sub {
			push @{$_[1]}, 'string';
			return $_[1];
		},
	);
	
	factory add => 0 => (
		[ArrayRef] => sub { die 'kaput' }
	);

	factory add => 0 => sub { die 'fallback' };

	1;
}

my $c = Custom->new();

is_deeply($c->add('one'), [ 'leadership', 'propaganda', 'finance', 'string', 'people', 'string string', 'string' ]);

is_deeply($c->boat, [ 'leadership', 'propaganda', 'finance', 'string', 'people', 'string string', 'string' ]);

$c = Extendings->new();

is_deeply($c->add('one'), [ 'leadership', 'propaganda', 'finance', 'string', 'people', 'string string', 'string', 'string' ]);

is_deeply($c->boat, [ 'leadership', 'propaganda', 'finance', 'string', 'people', 'string string', 'string' ]);

eval {
	$c->add([qw/1 2 3/]);
};

like($@, qr/kaput/);

eval {
	$c->add({qw/1 2 3 4/});
};

like($@, qr/fallback/);

ok(1);

done_testing();
