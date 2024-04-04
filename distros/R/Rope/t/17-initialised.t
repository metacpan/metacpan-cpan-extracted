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

	property one => (
		initable => 1,
		writeable => 1,
		enumerable => 1,
		builder => sub {
			return 'kaput'
		},
		trigger => sub {
			my ($self, $value) = @_;
			$self->{count}++;
			return $value;
		}
	);

	1;
}

my $k = Locked->new();

is($k->{one}, 'kaput');

my $init = Rope->get_initialised('Locked', 0);

is($init->{one}, 'kaput');

$init->{one} = 'okay';

is($init->{one}, 'okay');

is($k->{one}, 'okay');

ok(1);

done_testing();
