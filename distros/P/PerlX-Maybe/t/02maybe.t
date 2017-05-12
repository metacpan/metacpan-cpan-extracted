use Test::More tests => 3;
use PerlX::Maybe;

is_deeply(
	[ maybe foo => undef, maybe bar => 0, maybe baz => 1, undef ],
	[ bar => 0, baz => 1, undef ],
	);

is_deeply(
	[ 3, maybe foo => undef, 4, maybe bar => 0, 5, maybe baz => 1 ],
	[ 3, 4, bar => 0, 5, baz => 1 ],
	);

is_deeply(
	[ 3, maybe foo => {quux=>1}, undef, 4, maybe bar => 0, 5, maybe baz => 1 ],
	[ 3, foo => {quux=>1}, undef, 4, bar => 0, 5, baz => 1 ],
	);

