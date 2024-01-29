use Test::More;

use Rope (no_import => 1);
use Types::Standard qw/Int/;

my $k = Rope->new({
	properties => [
		one => 1,
		two => {
			type => Int,
			value => 2,
			writeable => 0,
			enumerable => 0,
		},
		three => sub {
			my ($self, $int) = @_;
			$self->{two} + $int;
		}
	]
});

is($k->{one}, 1);
is($k->{two}, 2);

my @keys = sort keys %{$k};

is_deeply(\@keys, [qw/one three/]);

$k->{one} = 10;
is($k->{one}, 10);

eval {
	$k->{two} = 50;
};

like($@, qr/Cannot set Object \(Rope::Anonymous0\) property \(two\) it is only readable/);

$k = Rope->new({
	use => [
		'Rope::Autoload'
	],
	with => [
		'Rope::Anonymous0'
	],
	requires => [
		qw/one two three/
	]
});

is($k->one, 1);
is($k->two, 2);

my @keys = sort keys %{$k};

is_deeply(\@keys, [qw/one three/]);

$k->{one} = 10;
is($k->{one}, 10);

eval {
	$k->{two} = 50;
};

like($@, qr/Cannot set Object \(Rope::Anonymous1\) property \(two\) it is only readable/);

done_testing();
