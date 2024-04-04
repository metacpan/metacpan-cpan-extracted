use Test::More;
use Rope;

{
	package Custom;

	use Rope;
	use Rope::Autoload;

	property one => (
		initable => 1,
		writeable => 0,
		enumerable => 1,
		builder => sub {
			return 'kaput'
		}	
	);

	property two => (
		writeable => 0,
		enumerable => 0,
		builder => sub {
			$_[0]->{properties}->{three} = {
				value => 'works',
				writeable => 0
			};
			return $_[0]->{properties}->{one}->{value} . 2;
		}
	);

	1;
}

my $k = Custom->new();

is($k->{one}, 'kaput');

is($k->{two}, 'kaput2');

is($k->{three}, 'works');

my $o = Rope->new({
	properties => [
		one => 'kaput',
		two => {
			writeable => 0,
			enumerable => 0,
			builder => sub {
				$_[0]->{properties}->{three} = {
					value => 'works',
					writeable => 0
				};
				return $_[0]->{properties}->{one}->{value} . 2;
			}
		}
	]
});

is($o->{one}, 'kaput');

is($o->{two}, 'kaput2');

is($o->{three}, 'works');

ok(1);

done_testing();
