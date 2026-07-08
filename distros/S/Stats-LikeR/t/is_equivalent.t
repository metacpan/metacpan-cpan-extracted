#!/usr/bin/env perl

require 5.010;
use warnings FATAL => 'all';
use utf8;
use Stats::LikeR;
use Test::Exception; # throws_ok / dies_ok
use Test::More;
use Test::LeakTrace 'no_leaks_ok';

# is_equivalent: 1 iff every arg array ref shares one distinct-value set
# (multiplicity + order ignored), generalising List::Compare is_LequivalentR
# to N lists; else 0.

#--------
# two lists, plainly equivalent / not
#--------
is( is_equivalent([1,2,3], [1,2,3]),       1, 'identical two lists' );
is( is_equivalent([1,2,3], [3,2,1]),       1, 'order is irrelevant' );
is( is_equivalent([1,2,3], [1,2]),         0, 'right is missing a value' );
is( is_equivalent([1,2],   [1,2,3]),       0, 'right has an extra value (foreign key)' );

#--------
# multiplicity ignored, per-ref dedup path (the `continue` branch)
#--------
is( is_equivalent([1,1,1,2], [2,2,1]),     1, 'duplicates on both sides, same set' );
is( is_equivalent([1,1],     [1]),         1, 'left all-duplicate, right single' );

#--------
# stringification: numbers and their string forms collide as keys
#--------
is( is_equivalent([1,2,3], ['1','2','3']), 1, 'numeric vs string keys stringify equal' );
is( is_equivalent([1,2],   ['1','2.0']),   0, '2 and "2.0" are distinct keys' );

#--------
# empties
#--------
is( is_equivalent([], []),                 1, 'empty vs empty' );
is( is_equivalent([], [1]),                0, 'empty vs non-empty (foreign key on right)' );
is( is_equivalent([1], []),                0, 'non-empty vs empty (matched != ref_size)' );

#--------
# N-way (> 2 refs)
#--------
is( is_equivalent([1,2,3], [3,1,2], [2,3,1]),        1, 'three equivalent lists' );
is( is_equivalent([1,2,3], [3,1,2], [2,3,1,4]),      0, 'third list has an extra value' );
is( is_equivalent([1,2,3], [3,1,2], [2,3]),          0, 'third list is missing a value' );
is( is_equivalent([1,2], [1,2], [1,2], [1,2], [1,2]),1, 'five equivalent lists' );

#--------
# same ref passed twice
#--------
{
	my @a = (5, 9, 5, 'x');
	is( is_equivalent(\@a, \@a),            1, 'a list is equivalent to itself' );
}

#--------
# UTF-8 keys
#--------
is( is_equivalent(['café','naïve'], ['naïve','café']),   1, 'utf8 keys, reordered' );
is( is_equivalent(['café'], ['cafe']),                   0, 'utf8 vs ascii differ' );

#--------
# error paths
#--------
throws_ok { is_equivalent([1,2,3]) }
	qr/needs >= 2 array refs/,                'single arg croaks';
throws_ok { is_equivalent() }
	qr/needs >= 2 array refs/,                'no args croaks';
throws_ok { is_equivalent('not a ref', [1]) }
	qr/argument index 0 .* is not an array reference/,
	'non-arrayref first arg croaks';
throws_ok { is_equivalent([1,2], {a=>1}) }
	qr/argument index 1 .* is not an array reference/,
	'non-arrayref later arg croaks';
throws_ok { is_equivalent([1,undef,3], [1,2,3]) }
	qr/undefined value at array ref index 1 \(argument 0\)/,
	'undef in first ref croaks';
throws_ok { is_equivalent([1,2,3], [1,undef,3]) }
	qr/undefined value at array ref index 1 \(argument 1\)/,
	'undef in later ref croaks';

#--------
# returns a single scalar in list context (predicate, not a set)
#--------
{
	my @got = is_equivalent([1,2,3], [3,2,1]);
	is( scalar(@got), 1, 'list context yields exactly one value' );
	is( $got[0],      1, 'that value is the boolean result' );
}

#--------
# no memory leaks (guarded under Devel::Cover)
#--------
unless ($INC{'Devel/Cover.pm'}) {
	no_leaks_ok {
		eval { is_equivalent([1,1,2], [2,2,1]) }
	} 'is_equivalent(): equivalent path, no memory leaks';

	no_leaks_ok {
		eval { is_equivalent([1,2,3], [1,2,3,4]) }
	} 'is_equivalent(): foreign-key path, no memory leaks';

	no_leaks_ok {
		eval { is_equivalent([1,2,3], [1,2]) }
	} 'is_equivalent(): missing-value path, no memory leaks';

	no_leaks_ok {
		eval { is_equivalent(['café'], ['café','x']) }
	} 'is_equivalent(): utf8 path, no memory leaks';

	no_leaks_ok {
		eval { is_equivalent([1,2,3]) }
	} 'is_equivalent(): items<2 croak, no memory leaks';

	no_leaks_ok {
		eval { is_equivalent([1,2], 'bad') }
	} 'is_equivalent(): non-arrayref croak, no memory leaks';

	no_leaks_ok {
		eval { is_equivalent([1,undef], [1,2]) }
	} 'is_equivalent(): undef-value croak, no memory leaks';
}

done_testing();
