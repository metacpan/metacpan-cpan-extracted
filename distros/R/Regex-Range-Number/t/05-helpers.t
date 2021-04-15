use Test::More;

use Regex::Range::Number qw/all/;

is_deeply( 
	$helper{zip}(70,99),
	[
		[ 7, 9 ],
		[ 0, 9 ]
	]
);

is($helper{compare}(5, 1), 1);
is($helper{compare}(1, 5), -1);
is($helper{compare}(1, 1), 0);

is_deeply(
	[$helper{push}([qw/a b c/], 'a')],
	[qw/a b c/]
); 


is($helper{contains}([ { string => 'abc' } ], 'string', 'abc'), 1);
is($helper{contains}([ { string => 'abc' } ], 'string', 'def'), undef);

is_deeply($helper{nines}(100, 1), 109);
is_deeply($helper{nines}(100, 2), 199);

is($helper{zeros}(1999, 1), 1991);

done_testing();

1;
