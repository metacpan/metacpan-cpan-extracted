use Test::More;
use Rope;

{
	package Locked;

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

my $k = Locked->new();

is($k->{one}, 'kaput');

is($k->{two}, 'kaput2');

is($k->{three}, 'works');

$k->{four} = 'okay';

is($k->{four}, 'okay');

$k->locked(1);

eval {
	$k->{five} = 'kaput';
};

like($@, qr/Object \(Locked\) is locked you cannot extend with new properties/, 'Failed to set a key as object is locked');

{
	package Locked::Loaded;

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

	locked;

	1;
}


my $k = Locked::Loaded->new();

is($k->{one}, 'kaput');

is($k->{two}, 'kaput2');

is($k->{three}, 'works');

eval {
	$k->{four} = 'okay';
};

like($@, qr/Object \(Locked::Loaded\) is locked you cannot extend with new properties/, 'Failed to set a key as object is locked');

$k->locked(0);

$k->{five} = 'unlocked';

is($k->{five}, 'unlocked');

my $o = Rope->new({
	properties => [
		one => 'kaput',
		two => {
			initable => 1,
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

$o->{four} = '4';

is($o->{four}, 4);

$o->locked(1);

eval {
	$o->{five} = 'kaput';
};

like($@, qr/Object \(Rope::Anonymous0\) is locked you cannot extend with new properties/, 'error as locked');

my $p = Rope->new({
	locked => 1,
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

is($p->{one}, 'kaput');

is($p->{two}, 'kaput2');

is($p->{three}, 'works');

eval {
	$p->{four} = 'okay';
};

like($@, qr/Object \(Rope::Anonymous1\) is locked you cannot extend with new properties/, 'Failed to set a key as object is locked');

$k->locked(0);

$k->{five} = 'unlocked';

is($k->{five}, 'unlocked');

ok(1);

done_testing();
