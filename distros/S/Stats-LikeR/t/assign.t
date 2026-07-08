#!/usr/bin/env perl
require 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Stats::LikeR;

# --- optional test modules: import if present, else install skipping stubs ---
BEGIN {
	if (eval { require Test::Exception; 1 }) {
		Test::Exception->import;
	} else {
		*throws_ok = sub (&;$$) { SKIP: { skip 'Test::Exception not installed', 1 } };
		*dies_ok   = sub (&;$)	{ SKIP: { skip 'Test::Exception not installed', 1 } };
		*lives_ok  = sub (&;$)	{ SKIP: { skip 'Test::Exception not installed', 1 } };
	}
	if (eval { require Test::LeakTrace; 1 }) {
		Test::LeakTrace->import('no_leaks_ok');
	} else {
		*no_leaks_ok = sub (&;$) { SKIP: { skip 'Test::LeakTrace not installed', 1 } };
	}
}

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
	assign(undef, 'x');
} 'assign: dies when given undefined data';

# ----------------------------------------------------------------------
# AoH: basic derivation, in-place return, chaining, originals preserved
# ----------------------------------------------------------------------
{
	my $aoh = [
		{ weight => 70, height => 1.75 },
		{ weight => 90, height => 1.80 },
		{ weight => 50, height => 1.60 },
	];
	my $ret = assign($aoh,
		bmi	  => sub { $_->{weight} / $_->{height} ** 2 },
		bmi_r => sub { sprintf '%.1f', $_->{bmi} },		# uses the column just made
	);
	is($ret, $aoh, 'AoH: returns the same ref (modified in place)');
	is_approx($aoh->[0]{bmi}, 22.857142857, 'AoH bmi row 0');
	is_approx($aoh->[1]{bmi}, 27.777777778, 'AoH bmi row 1');
	is_approx($aoh->[2]{bmi}, 19.531250000, 'AoH bmi row 2');
	is($aoh->[2]{bmi_r}, '19.5', 'AoH: later pair sees earlier new column');
	is($aoh->[0]{weight}, 70, 'AoH: existing columns untouched');
}

# AoH: row index via $_[1], and overwriting an existing column
{
	my $d = [ { x => 10 }, { x => 20 }, { x => 30 } ];
	assign($d,
		idx => sub { $_[1] },				 # second arg is the row index
		x	=> sub { $_->{x} * 2 },			 # overwrite in place
	);
	is_deeply([ map { $_->{idx} } @$d ], [0, 1, 2], 'AoH: row index from $_[1]');
	is_deeply([ map { $_->{x} } @$d ], [20, 40, 60], 'AoH: overwrites existing column');
}

# AoH: whole-column coderef -- a list return (>1 value) fills the whole column
{
	my $d = [ { v => 1 }, { v => 2 }, { v => 3 } ];
	assign($d, w => sub { (10, 20, 30) });
	is_deeply([ map { $_->{w} } @$d ], [10, 20, 30],
		'AoH: whole-column coderef distributes a list positionally');
}

# AoH: arrayref value -- a ready-made column, copied in
{
	my $d = [ { v => 1 }, { v => 2 }, { v => 3 } ];
	my @src = (100, 200, 300);
	assign($d, col => \@src);
	is_deeply([ map { $_->{col} } @$d ], [100, 200, 300],
		'AoH: arrayref value becomes the column');
	$src[0] = 999;
	is($d->[0]{col}, 100, 'AoH: arrayref value is copied, not aliased');
}

# AoH: a single arrayref return is a per-row cell, NOT a column
{
	my $d = [ { v => 1 }, { v => 2 } ];
	assign($d, cell => sub { [5, 6] });
	is_deeply($d->[0]{cell}, [5, 6], 'AoH: single arrayref return stays a per-row cell (row 0)');
	is_deeply($d->[1]{cell}, [5, 6], 'AoH: single arrayref return stays a per-row cell (row 1)');
}

# AoH: rank() integration -- the motivating whole-column use case
SKIP: {
	skip 'rank() not available', 3 unless defined &rank;
	my $d = [ { v => 30 }, { v => 10 }, { v => 20 } ];
	assign($d, r => sub { rank( map { $_->{v} } @$d ) });
	is($d->[0]{r}, 3, 'AoH: rank() whole-column, 30 -> rank 3');
	is($d->[1]{r}, 1, 'AoH: rank() whole-column, 10 -> rank 1');
	is($d->[2]{r}, 2, 'AoH: rank() whole-column, 20 -> rank 2');
}

# AoH: length mismatch dies for both column-value kinds
{
	throws_ok { assign([ {}, {}, {} ], bad => [1, 2]) }
		qr/2 values but data frame has 3 rows/,
		'AoH: arrayref column length mismatch dies';
	throws_ok { assign([ {}, {}, {} ], bad => sub { (1, 2) }) }
		qr/produced 2 values but data frame has 3 rows/,
		'AoH: whole-column length mismatch dies';
}

# ----------------------------------------------------------------------
# HoA: basic derivation, chaining, branching, originals shared/untouched
# ----------------------------------------------------------------------
{
	my $hoa = { weight => [70, 90, 50], height => [1.75, 1.80, 1.60] };
	my $ret = assign($hoa,
		bmi => sub { $_->{weight} / $_->{height} ** 2 },
		tag => sub { $_->{bmi} > 25 ? 'high' : 'ok' },	# uses new col
	);
	is($ret, $hoa, 'HoA: returns the same ref (modified in place)');
	is(scalar @{ $hoa->{bmi} }, 3, 'HoA: new column has n entries');
	is_approx($hoa->{bmi}[1], 27.777777778, 'HoA bmi row 1');
	is_deeply($hoa->{tag}, ['ok', 'high', 'ok'], 'HoA: chained column + branching');
	is_deeply($hoa->{weight}, [70, 90, 50], 'HoA: existing column untouched');
}

# HoA: ragged columns -> missing cells are undef in the row view
{
	my $hoa = { x => [1, 2, 3], y => [10, 20] };		# y is short
	assign($hoa, z => sub { ($_->{x} // 0) + ($_->{y} // 0) });
	is_deeply($hoa->{z}, [11, 22, 3], 'HoA: ragged column, undef cell treated as missing');
}

# HoA: whole-column coderef fills the whole new column
{
	my $hoa = { a => [1, 2, 3], b => [4, 5, 6] };
	assign($hoa, c => sub { (100, 200, 300) });
	is_deeply($hoa->{c}, [100, 200, 300], 'HoA: whole-column coderef sets entire column');
}

# HoA: arrayref value -- ready-made column, copied in
{
	my $hoa = { a => [1, 2, 3] };
	my @src = (7, 8, 9);
	assign($hoa, d => \@src);
	is_deeply($hoa->{d}, [7, 8, 9], 'HoA: arrayref value becomes the column');
	$src[0] = 999;
	is($hoa->{d}[0], 7, 'HoA: arrayref value is copied, not aliased');
}

# HoA: length mismatch dies for both column-value kinds
{
	throws_ok { assign({ a => [1, 2, 3] }, bad => [1, 2]) }
		qr/2 values but data frame has 3 rows/,
		'HoA: arrayref column length mismatch dies';
	throws_ok { assign({ a => [1, 2, 3] }, bad => sub { (1, 2) }) }
		qr/produced 2 values but data frame has 3 rows/,
		'HoA: whole-column length mismatch dies';
}

# ----------------------------------------------------------------------
# Edge cases: empty frames (coderef and arrayref value)
# ----------------------------------------------------------------------
{
	my $empty_aoh = [];
	assign($empty_aoh, c => sub { 1 });
	is_deeply($empty_aoh, [], 'empty AoH stays empty (coderef)');
	assign($empty_aoh, c2 => []);
	is_deeply($empty_aoh, [], 'empty AoH stays empty (arrayref value)');

	my $empty_hoa = { a => [] };
	assign($empty_hoa, b => sub { 1 });
	is_deeply($empty_hoa->{b}, [], 'empty HoA column -> empty new column (coderef)');
	assign($empty_hoa, d => []);
	is_deeply($empty_hoa->{d}, [], 'empty HoA column -> empty new column (arrayref value)');
}

# ----------------------------------------------------------------------
# Error paths
# ----------------------------------------------------------------------
{
	throws_ok { assign([{}], 'lonely') } qr/even list/,
		'odd-length pair list croaks';
	throws_ok { assign([{}], n => 5) } qr/CODE or ARRAY/,
		'non-code/arrayref value croaks';
	throws_ok { assign('scalar', x => sub { 1 }) } qr/data frame/,
		'scalar data frame croaks';
	throws_ok { assign([ { ok => 1 }, 'notahash' ], 'y' => sub { 1 }) } qr/row 1 is not a hashref/,
		'AoH non-hash row croaks (with index)';
	lives_ok { assign([{ a => 1 }], b => sub { $_->{a} + 1 }) }
		'a well-formed call lives';
}

# ----------------------------------------------------------------------
# Leak guards (SV-level). Each block builds a throwaway frame so everything
# is freed at block exit; skipped under Devel::Cover.
# ----------------------------------------------------------------------
SKIP: {
	skip 'leak checks skipped under Devel::Cover', 5 if $INC{'Devel/Cover.pm'};

	no_leaks_ok {
		my $d = [ { w => 70, h => 1.8 }, { w => 90, h => 1.7 } ];
		assign($d, bmi => sub { $_->{w} / $_->{h} ** 2 });
	} 'no SV leak: AoH per-row derivation';

	no_leaks_ok {
		my $d = [ { v => 1 }, { v => 2 }, { v => 3 } ];
		assign($d, w => sub { (10, 20, 30) });
	} 'no SV leak: AoH whole-column coderef';

	no_leaks_ok {
		my $d = [ { v => 1 }, { v => 2 } ];
		assign($d, c => [3, 4]);
	} 'no SV leak: AoH arrayref value';

	no_leaks_ok {
		my $d = { w => [70, 90], h => [1.8, 1.7] };
		assign($d, bmi => sub { $_->{w} / $_->{h} ** 2 }, tag => sub { $_->{bmi} > 25 ? 1 : 0 });
	} 'no SV leak: HoA derivation (synthesized row views)';

	no_leaks_ok {
		eval { assign([ { a => 1 } ], bad => 'notcode') };
	} 'no SV leak on the croak path';
}

done_testing;
