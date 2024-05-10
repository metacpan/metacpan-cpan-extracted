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
			return $_[0]->{properties}->{one}->{value} . 2;
		}
	);

	sub INITIALISED {
		$_[0]->three = 'works';
	}

	1;
}

{
	package Custom1;

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
			return $_[0]->{properties}->{one}->{value} . 2;
		}
	);

	function INITIALISED => sub {
		$_[0]->three = 'works';
	};

	1;
}



my $k = Custom->new();

is($k->{one}, 'kaput');

is($k->{two}, 'kaput2');

is($k->{three}, 'works');

ok(1);

my $o = Rope->new({
	properties => [
		one => 'kaput',
		two => {
			writeable => 0,
			enumerable => 0,
			builder => sub {
				return $_[0]->{properties}->{one}->{value} . 2;
			}
		}
	],
	INITIALISED => sub {
		$_[0]->{three} = 'works';
	}
});

is($o->{one}, 'kaput');

is($o->{two}, 'kaput2');

is($o->{three}, 'works');

done_testing();
