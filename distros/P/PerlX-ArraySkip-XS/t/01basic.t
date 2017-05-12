use Test::More tests => 4;
BEGIN { use_ok('PerlX::ArraySkip::XS', 'arrayskip') };

is_deeply(
	[ arrayskip 0 .. 10 ],
	[ 1 .. 10 ],
);

is_deeply(
	[ 1, arrayskip 2, 3, arrayskip 4, 5, arrayskip 6, 7, arrayskip 8 ],
	[ 1, 3, 5, 7 ],
);

is_deeply(
	[ arrayskip ],
	[ ],
);
