#!/usr/bin/env perl

require 5.010;
use warnings FATAL => 'all';
use Stats::LikeR;
use Test::Exception; # dies_ok / throws_ok
use Test::More;
use Test::LeakTrace 'no_leaks_ok';

# Custom helper for floating-point comparisons
sub is_approx {
	my ($got, $expected, $test_name, $epsilon) = @_;
	$epsilon = 1e-7 if not defined $epsilon;
	my $current_sub = ( split( /::/, ( caller(0) )[3] ) )[-1];
	my $i = 0;
	foreach my $arg ($got, $expected, $test_name) {
		next if defined $arg;
		die "\$arg[$i] (see subroutine signature for name) isn't defined in $current_sub";
		$i++;
	}
	my $diff = abs($got - $expected);
	if ($diff <= $epsilon) {
		pass("$test_name: within $epsilon");
		return 1;
	} else {
		fail($test_name);
		diag("         got: $got\n    expected: $expected; diff = $diff");
		return 0;
	}
}

#--------
# ties.method: distinct + every tie rule
#--------
is_deeply( [rank(3, 1, 4, 2, 5)],                             [3, 1, 4, 2, 5],          'distinct (average)' );
is_deeply( [rank(3, 1, 4, 1, 5)],                             [3, 1.5, 4, 1.5, 5],      'average, ties' );
is_deeply( [rank(3, 1, 4, 1, 5, 'ties.method', 'min')],       [3, 1, 4, 1, 5],          'min, ties' );
is_deeply( [rank(3, 1, 4, 1, 5, 'ties.method', 'max')],       [3, 2, 4, 2, 5],          'max, ties' );
is_deeply( [rank(3, 1, 4, 1, 5, 'ties.method', 'first')],     [3, 1, 4, 2, 5],          'first, ties' );
is_deeply( [rank(3, 1, 4, 1, 5, 'ties.method', 'last')],      [3, 2, 4, 1, 5],          'last, ties' );
is_approx( (rank(1, 1, 1))[0], 2, 'average of a 3-way tie is 2' );

#--------
# na.last handling (undef = NA), average ties
#--------
is_deeply( [rank(5, undef, 3, undef, 1)],                             [3, 4, 2, 5, 1], 'na.last true (default)' );
is_deeply( [rank(5, undef, 3, undef, 1, 'na.last', 'false')],         [5, 1, 4, 2, 3], 'na.last false' );
is_deeply( [rank(5, undef, 3, undef, 1, 'na.last', 'keep')],          [3, undef, 2, undef, 1], 'na.last keep' );
is_deeply( [rank(5, undef, 3, undef, 1, 'na.last', 'na')],            [3, 2, 1],       'na.last na (drop)' );
is_deeply( [rank(5, undef, 3, undef, 1, 'na.last', undef)],           [3, 2, 1],       'na.last undef == drop' );
is_deeply( [rank(10, undef, 10, 'ties.method', 'min', 'na.last', 'false')], [2, 1, 2], 'min + na.last false shift' );

#--------
# all-NA and single-element edge cases
#--------
is_deeply( [rank(undef, undef)],                        [1, 2],         'all NA, default' );
is_deeply( [rank(undef, undef, 'na.last', 'keep')],     [undef, undef], 'all NA, keep' );
is_deeply( [rank(undef, undef, 'na.last', 'na')],       [],             'all NA, drop -> empty' );
is_deeply( [rank(undef)],                               [1],            'single undef' );
is_deeply( [rank()],                                    [],             'no args -> empty' );
is_deeply( [rank(42)],                                  [1],            'single value' );

#--------
# input forms, negatives/floats, infinities, NaN
#--------
is_deeply( [rank([3, 1, 4, 1, 5])],                     [3, 1.5, 4, 1.5, 5], 'single array ref' );
is_deeply( [rank(3, [1, 4], 1, 5)],                     [3, 1.5, 4, 1.5, 5], 'mixed scalars + array ref' );
is_deeply( [rank(-2.5, 0, -2.5, 7)],                    [1.5, 3, 1.5, 4],    'negative floats, ties' );
is_deeply( [rank(1, 9 ** 9 ** 9, -9 ** 9 ** 9)],        [2, 3, 1],           '+/- infinity ordered' );
{
	my $nan = 9 ** 9 ** 9; $nan -= $nan;
	is_deeply( [rank(2, $nan, 1, 'na.last', 'keep')],   [2, undef, 1],       'NaN treated as NA' );
}

#--------
# random: a permutation of 1..n with non-tied values fixed
#--------
{
	srand(20240607);
	my @x = (5, 2, 2, 2, 9, 1);          # three 2s tie over ranks 2,3,4
	my @r = rank(@x, 'ties.method', 'random');
	is( $r[0], 5, 'random: untied value 5 keeps its rank' );
	is( $r[4], 6, 'random: untied value 9 keeps its rank' );
	is( $r[5], 1, 'random: untied value 1 keeps its rank' );
	is_deeply( [sort { $a <=> $b } @r[1, 2, 3]], [2, 3, 4], 'random: tied group fills ranks 2,3,4' );
}

#--------
# error handling
#--------
throws_ok { rank(1, 2, 'ties.method', 'bogus') } qr/rank: unknown ties.method/, 'bad ties.method dies';
throws_ok { rank(1, 2, 'na.last', 'bogus') }     qr/rank: unknown na.last/,     'bad na.last dies';
throws_ok { rank([1, 2], 'na.last') }            qr/rank: named options must be key => value pairs/, 'odd option list dies';

#--------
# leak checks (real calls hoisted out of the closures)
#--------
unless ($INC{'Devel/Cover.pm'}) {
	my @warm;
	@warm = rank(3, 1, 4, 1, 5);
	@warm = rank(5, undef, 3, undef, 1, 'na.last', 'keep');
	@warm = rank(5, undef, 3, undef, 1, 'na.last', 'false');
	@warm = rank([3, 1, 4, 1, 5], 'ties.method', 'max');
	@warm = rank(1, 2, 'ties.method', 'random');
	@warm = rank();

	no_leaks_ok { my @r = rank(3, 1, 4, 1, 5) }                        'average: no leaks';
	no_leaks_ok { my @r = rank(5, undef, 3, undef, 1, 'na.last', 'keep') }  'keep: no leaks';
	no_leaks_ok { my @r = rank(5, undef, 3, undef, 1, 'na.last', 'false') } 'false: no leaks';
	no_leaks_ok { my @r = rank([3, 1, 4, 1, 5], 'ties.method', 'max') }     'max/ref: no leaks';
	no_leaks_ok { my @r = rank(1, 2, 'ties.method', 'random') }        'random: no leaks';
	no_leaks_ok { my @r = rank() }                                     'empty: no leaks';
}

done_testing();
