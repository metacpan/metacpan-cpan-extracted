use Test::More;
use Rope;

{
	package Locked;

	use Rope;
	use Rope::Autoload;

	property count => (
		value => 0,
		configurable => 1,
		enumerable => 1
	);

	function two => sub {
		my ($self, $count) = @_;
		$self->count = $count;
		return $self->count;
	};

	function three => sub {
		my ($self, $count) = @_;
		return $self->two($count);
	};

	1;
}

{
	package Loaded;

	use Rope;
	extends 'Locked';

	before count => sub {
		my ($self, $val) = @_;
		$val = $val * 2;
		return $val;
	};

	before three => sub {
		my ($self, $val) = @_;
		$val = $val * 4;
		return $val;
	};

	before three => sub {
		my ($self, $val) = @_;
		$val = $val * 4;
		return $val;
	};
}

my $k = Locked->new();

is($k->two(10), 10);

is($k->{count}, 10);

is($k->three(20), 20);

is($k->{count}, 20);

my $n = Loaded->new();

is($n->two(10), 20);

is($n->three(10), 320);

ok(1);

done_testing();
