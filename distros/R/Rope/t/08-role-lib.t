use Test::More;

use lib 't/lib';
use Custom;
my $k = Custom->new();

is($k->one, 1);
is($k->two, 2);

my @keys = keys %{$k};

is_deeply(\@keys, [qw/one/]);

$k->one = 10;

is($k->one, 10);

eval {
	$k->two = 50;
};

like($@, qr/Cannot set Object \(Custom\) property \(two\) it is only readable/);

is($k->{three}(10), 12);

ok(1);

done_testing();
