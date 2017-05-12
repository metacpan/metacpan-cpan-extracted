use Test::More tests => 4;
BEGIN { use_ok('PerlX::ArraySkip', 'askip') };

is_deeply(
	[ askip 0 .. 10 ],
	[ 1 .. 10 ],
);

is_deeply(
	[ 1, askip 2, 3, askip 4, 5, askip 6, 7, askip 8 ],
	[ 1, 3, 5, 7 ],
);

is_deeply(
	[ askip ],
	[ ],
);
