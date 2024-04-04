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
is($k->{count}, 1);

$k->{one} = 'count';
is($k->{count}, 2);

$k->destroy();

my $o = Rope->new({
	properties => [
		count => 0,
		one => {
			value =>  'kaput',
			writeable => 1,
			trigger => sub {
				my ($self, $value) = @_;
				$self->{count}++;
				return $value;
			}	
		}
	]
});

is($o->{one}, 'kaput');
is($o->{count}, 1);

$o->{one} = 'count';
is($o->{count}, 2);

$k->destroy();

ok(1);

done_testing();
