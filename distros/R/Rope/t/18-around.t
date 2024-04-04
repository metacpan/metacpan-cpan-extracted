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

	around count => sub {
		my ($self, $cb, $val) = @_;
		$val = $val * 2;
		return $cb->($val);
	};

	around three => sub {
		my ($self, $cb, $val) = @_;
		$val = $val * 4;
		return ($cb->($val), 'extra');
	};

	around three => sub {
		my ($self, $cb, $val) = @_;
		$val = $val * 4;
		return $cb->($val);
	};

}

my $k = Locked->new();

is($k->two(10), 10);

is($k->{count}, 10);

is($k->three(20), 20);

is($k->{count}, 20);

my $n = Loaded->new();

is($n->two(10), 20);

my @params = $n->three(10);

is($params[0], 320);
is($params[1], 'extra');

ok(1);

done_testing();
