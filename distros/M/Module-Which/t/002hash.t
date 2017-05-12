
use Test::More tests => 9;
BEGIN { use_ok('Data::Hash::Transform', qw(hash_l hash_f hash_m hash_a hash_em)) };

my $loh =   [ { k => 1, n => 'one' }, { k => 2, n => 'two' }, { k => 1, n => 'ein' } ];

# testing hash_f, hash_l, hash_m, hash_a

is_deeply(
	hash_f($loh, 'k'),
	{ 1 => { k => 1, n => 'one' }, 2 => { k => 2, n => 'two' } },
	"hash_f works"
);

is_deeply(
	hash_l($loh, 'k'),
	{ 1 => { k => 1, n => 'ein' }, 2 => { k => 2, n => 'two' } },
	"hash_l works"
);

is_deeply(
	hash_m($loh, 'k'),
	{ 1 => [ { k => 1, n => 'one' }, { k => 1, n => 'ein' } ], 2 => { k => 2, n => 'two' } },
	"hash_m works"
);

is_deeply(
	hash_a($loh, 'k'),
	{ 1 => [ { k => 1, n => 'one' }, { k => 1, n => 'ein' } ], 2 => [ { k => 2, n => 'two' } ] },
	"hash_a works"
);

# testing hash_em

is_deeply(
	hash_em($loh, 'k', 'f'),
	{ 1 => { k => 1, n => 'one' }, 2 => { k => 2, n => 'two' } },
	"hash_em (method 'f') works"
);

is_deeply(
	hash_em($loh, 'k', 'l'),
	{ 1 => { k => 1, n => 'ein' }, 2 => { k => 2, n => 'two' } },
	"hash_em (method 'l') works"
);

is_deeply(
	hash_em($loh, 'k', 'm'),
	{ 1 => [ { k => 1, n => 'one' }, { k => 1, n => 'ein' } ], 2 => { k => 2, n => 'two' } },
	"hash_em (method 'm') works"
);

is_deeply(
	hash_em($loh, 'k', 'a'),
	{ 1 => [ { k => 1, n => 'one' }, { k => 1, n => 'ein' } ], 2 => [ { k => 2, n => 'two' } ] },
	"hash_em (method 'a') works"
);

