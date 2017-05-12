use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More;

use PEF::CacheLRU;

my $cache = PEF::CacheLRU->new(1);

is $cache->set(a => 1), 1;
is $cache->get('a'), 1;

is $cache->set(b => 2), 2;
ok !defined $cache->get('a');
is $cache->get('b'), 2;

$cache = PEF::CacheLRU->new(2);

is $cache->set(a => 1), 1;
is $cache->get('a'), 1;

is $cache->set(b => 2), 2;
is $cache->get('a'), 1;
is $cache->get('b'), 2;

is $cache->set(c => 3), 3;
ok !defined $cache->get('a');
is $cache->get('b'), 2;
is $cache->get('c'), 3;

$cache = PEF::CacheLRU->new(3);

ok !defined $cache->get('a');

is $cache->set(a => 1), 1;
is $cache->get('a'), 1;

is $cache->set(b => 2), 2;
is $cache->get('a'), 1;
is $cache->get('b'), 2;

is $cache->set(c => 3), 3;
is $cache->get('a'), 1;
is $cache->get('b'), 2;
is $cache->get('c'), 3;

is $cache->set(b => 4), 4;
is $cache->get('a'), 1;
is $cache->get('b'), 4;
is $cache->get('c'), 3;

is $cache->get('a'), 1;    # the order is now a => c => b
is $cache->set(d => 5), 5;
is $cache->get('a'), 1;
ok !defined $cache->get('b');
is $cache->get('c'), 3;
is $cache->get('d'), 5;    # the order is now d => c => a

is $cache->set('e', 6), 6;
ok !defined $cache->get('a');
ok !defined $cache->get('b');
is $cache->get('c'), 3;
is $cache->get('d'), 5;
is $cache->get('e'), 6;

is $cache->remove('d'), 5;
is $cache->get('c'),    3;
ok !defined $cache->get('d');
is $cache->get('e'), 6;

$cache = PEF::CacheLRU->new(5);

my ($hit, $miss) = (0, 0);

for (1 .. 2000) {
	my $key = 1 + int rand 8;
	if ($cache->get($key)) {
		$hit++;
	} else {
		$miss++;
		$cache->set($key => $key);
	}
}

cmp_ok($hit, '>=', $miss, "more cache hits than misses during random access of small sigma ($hit >= $miss)");

($hit, $miss) = (0, 0);

for (1 .. 100) {
	foreach my $key (1 .. 10) {
		if ($cache->get($key)) {
			$hit++;
		} else {
			$miss++;
			$cache->set($key => $key);
		}
	}
}

cmp_ok($hit, '<=', $cache->size * 3, "no significant hits during linear scans ($hit)");

done_testing;
