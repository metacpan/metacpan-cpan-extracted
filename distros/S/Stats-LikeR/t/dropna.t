#!/usr/bin/env perl
require 5.010;
use warnings FATAL => 'all';
use Scalar::Util 'looks_like_number';
use Test::Exception; # die_ok
use Test::More;
use Stats::LikeR;
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
		diag("		   got: $got\n	  expected: $expected; diff = $diff");
		return 0;
	}
}

dies_ok {
	dropna(undef);
} 'dropna: dies when given undefined data';
#--------
# HoA cols (the motivating example, how => 'any' default)
#--------
{
	my $df = { A => [1, 2, undef], B => [1, 2, 3], C => [undef, 2, 4] };
	my $out = dropna($df, cols => ['A', 'B']);
	is_deeply($out, { A => [1, 2], B => [1, 2], C => [undef, 2] },
		'HoA cols: drop index 2 (A undef); C not checked but realigned');
	is_deeply($df, { A => [1, 2, undef], B => [1, 2, 3], C => [undef, 2, 4] },
		'HoA cols: original data frame untouched');
}

#--------
# HoA how => 'any' vs 'all'
#--------
{
	my $df = { A => [1, undef, undef], B => [9, 2, undef] };
	is_deeply(dropna($df, cols => ['A', 'B'], how => 'any'),
		{ A => [1], B => [9] }, 'HoA how=any drops rows 1 and 2');
	is_deeply(dropna($df, cols => ['A', 'B'], how => 'all'),
		{ A => [1, undef], B => [9, 2] }, 'HoA how=all drops only the all-undef row');
}

#--------
# HoA rows (literal index deletion, no NA logic)
#--------
{
	my $df = { A => [10, 20, 30, 40], B => ['a', 'b', 'c', 'd'] };
	is_deeply(dropna($df, rows => [1, 3]),
		{ A => [10, 30], B => ['a', 'c'] }, 'HoA rows: delete indices 1 and 3');
	is_deeply(dropna($df, rows => [99]),
		{ A => [10, 20, 30, 40], B => ['a', 'b', 'c', 'd'] },
		'HoA rows: an out-of-range index is ignored');
}

#--------
# AoH cols and rows
#--------
{
	my $df = [ { A => 1, B => 1 }, { A => undef, B => 2 }, { A => 3, B => undef } ];
	is_deeply(dropna($df, cols => ['A']),
		[ { A => 1, B => 1 }, { A => 3, B => undef } ],
		'AoH cols: drop the A-undef row');
	is_deeply(dropna($df, cols => ['A', 'B'], how => 'any'),
		[ { A => 1, B => 1 } ], 'AoH cols any over A and B');
	is_deeply(dropna($df, rows => [0, 2]),
		[ { A => undef, B => 2 } ], 'AoH rows: delete indices 0 and 2');
}

#--------
# HoH cols and rows
#--------
{
	my $df = { r1 => { A => 1, B => 2 }, r2 => { A => undef, B => 5 }, r3 => { A => 7, B => 8 } };
	is_deeply(dropna($df, cols => ['A']),
		{ r1 => { A => 1, B => 2 }, r3 => { A => 7, B => 8 } },
		'HoH cols: drop r2 (A undef)');
	is_deeply(dropna($df, rows => ['r1', 'r3']),
		{ r2 => { A => undef, B => 5 } }, 'HoH rows: delete keys r1 and r3');
}

#--------
# values survive intact (numeric cells)
#--------
{
	my $df = { mpg => [21, 22.8, undef], gear => [4, 3, 5] };
	my $out = dropna($df, cols => ['mpg']);
	is_approx($out->{mpg}[1], 22.8, 'surviving fractional value intact');
	ok(looks_like_number($out->{mpg}[0]), 'surviving cell is still numeric');
	is_deeply($out->{gear}, [4, 3], 'unchecked column realigned to survivors');
}

#--------
# empty / edge
#--------
is_deeply(dropna([], cols => ['A']), [], 'empty AoH -> empty');
is_deeply(dropna({}, rows => [0]), {}, 'empty HoA -> empty');
is_deeply(dropna({ A => [1, 2] }, cols => []), { A => [1, 2] }, 'empty cols subset keeps all');

#--------
# errors
#--------
throws_ok { dropna('scalar', cols => ['A']) } qr/data frame/,
	'scalar data frame dies';
throws_ok { dropna({ A => [1] }, cols => ['A'], rows => [0]) } qr/exactly one/,
	'both cols and rows dies';
throws_ok { dropna({ A => [1] }) } qr/exactly one/,
	'neither cols nor rows dies';
throws_ok { dropna({ A => [1] }, cols => 'A') } qr/must be an arrayref/,
	'non-arrayref selector dies';
throws_ok { dropna({ A => [1] }, cols => ['Z']) } qr/column 'Z' not found/,
	'a missing column dies';
throws_ok { dropna({ A => [1] }, cols => ['A'], how => 'maybe') } qr/'how' must be/,
	'an invalid how dies';
throws_ok { dropna({ A => [1] }, foo => 1) } qr/unknown argument/,
	'an unknown argument dies';
throws_ok { dropna({ A => [1], r => { x => 1 } }, cols => ['A']) } qr/ambiguous/,
	'a hashref mixing arrays and hashes dies';
lives_ok { dropna({ A => [1, undef] }, cols => ['A']) }
	'a well-formed call lives';

#--------
# memory
#--------
no_leaks_ok {
	my $x = dropna({ A => [1, 2, undef], B => [1, 2, 3] }, cols => ['A']);
} 'dropna: no memory leaks (HoA cols)' unless $INC{'Devel/Cover.pm'};

no_leaks_ok {
	my $x = dropna([ { A => 1 }, { A => undef } ], cols => ['A']);
} 'dropna: no memory leaks (AoH cols)' unless $INC{'Devel/Cover.pm'};

no_leaks_ok {
	eval { dropna({ A => [1] }, cols => ['Z']) };
} 'dropna: no memory leaks (die path)' unless $INC{'Devel/Cover.pm'};

done_testing;
