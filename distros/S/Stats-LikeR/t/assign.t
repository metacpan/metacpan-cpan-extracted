#!/usr/bin/env perl
require 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Stats::LikeR;

# optional test modules: import if present, else install skipping stubs
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

# AoH: basic derivation, in-place return, chaining, originals preserved
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

# AoH: map_cell -- in-place per-cell edit; $_ is the cell, return value ignored
{
	my $d = [ { 'Res.' => 'A:foo' }, { 'Res.' => 'B:bar' }, { 'Res.' => 'nocolon' } ];
	my $ret = assign($d, 'Res.' => map_cell { s/^[A-Z]:// });
	is($ret, $d, 'AoH map_cell: returns the same ref (modified in place)');
	is_deeply([ map { $_->{'Res.'} } @$d ], ['foo', 'bar', 'nocolon'],
		'AoH map_cell: in-place s/// edits the named column, return value ignored');
}

# AoH: map_cell exposes the row as $_[0] and the row index as $_[1]
{
	my $d = [ { v => 'x', n => 2 }, { v => 'y', n => 5 } ];
	assign($d, v => map_cell { $_ = "$_-$_[0]{n}-$_[1]" });
	is_deeply([ map { $_->{v} } @$d ], ['x-2-0', 'y-5-1'],
		'AoH map_cell: $_[0] is the row, $_[1] is the index');
}

# AoH: map_cell leaves undef cells untouched (undef in -> undef out); the block
# never runs on them, so no uninitialized-value warnings under FATAL warnings
{
	my $d = [ { s => 'A:foo' }, { s => undef }, {} ];   # defined, undef, missing
	my $ran = 0;
	assign($d, s => map_cell { $ran++; s/^[A-Z]:// });
	is($ran, 1, 'AoH map_cell: block runs only for the defined cell');
	is($d->[0]{s}, 'foo', 'AoH map_cell: defined cell edited');
	ok(!defined $d->[1]{s}, 'AoH map_cell: undef cell stays undef');
	ok(!exists $d->[2]{s}, 'AoH map_cell: missing cell stays missing');
}

# AoH: map_cell on a non-hash row dies with the offending index
{
	throws_ok { assign([ { ok => 1 }, 'notahash' ], x => map_cell { $_ = 1 }) }
		qr/row 1 is not a hashref/,
		'AoH map_cell: non-hash row croaks (with index)';
}

# HoA: basic derivation, chaining, branching, originals shared/untouched
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

# HoA: map_cell -- in-place per-cell edit; $_[0] is a row view for sibling cols
{
	my $hoa = { 'Res.' => ['A:foo', 'B:bar'], other => [1, 2] };
	my $ret = assign($hoa, 'Res.' => map_cell { s/^[A-Z]://; $_ .= '-' . $_[0]{other} });
	is($ret, $hoa, 'HoA map_cell: returns the same ref (modified in place)');
	is_deeply($hoa->{'Res.'}, ['foo-1', 'bar-2'],
		'HoA map_cell: in-place edit plus sibling column via $_[0]');
	is_deeply($hoa->{other}, [1, 2], 'HoA map_cell: sibling column untouched');
}

# HoA: map_cell leaves undef cells untouched (undef in -> undef out)
{
	my $hoa = { s => ['A:foo', undef, 'C:baz'] };
	my $ran = 0;
	assign($hoa, s => map_cell { $ran++; s/^[A-Z]:// });
	is($ran, 2, 'HoA map_cell: block skips the undef cell');
	is_deeply($hoa->{s}, ['foo', undef, 'baz'], 'HoA map_cell: undef cell stays undef');
}

# HoA: map_cell on a column that does not exist dies
{
	throws_ok { assign({ a => [1, 2] }, nope => map_cell { $_ = 1 }) }
		qr/map_cell target column 'nope' must already exist/,
		'HoA map_cell: missing target column croaks';
}

# HoA: the row view is not built for a cell the block will not see.
#
# The view used to be assembled before the "is this cell undef" test, so a
# column of undefs still paid for one view per row and threw every one of them
# away unread -- 0.161s of the 0.165s a 20000-row, 64-column pass cost. What
# the test can actually observe is that the sibling columns are never read, so
# a tied sibling that counts its FETCHes must see none.
{
	package Stats::LikeR::t::CountingFetch;
	require Tie::Array;
	our @ISA = ('Tie::StdArray');
	our $fetches = 0;
	sub FETCH { my ($self, $i) = @_; $fetches++; return $self->[$i] }
}
{
	my @sib;
	tie @sib, 'Stats::LikeR::t::CountingFetch';
	@sib = (10, 20, 30);
	my $hoa = { tgt => [undef, undef, undef], sib => \@sib };
	$Stats::LikeR::t::CountingFetch::fetches = 0;
	my $ran = 0;
	assign($hoa, tgt => map_cell { $ran++; $_ = $_[0]{sib} });
	is($ran, 0, 'HoA map_cell: block never runs for an all-undef column');
	is($Stats::LikeR::t::CountingFetch::fetches, 0,
		'HoA map_cell: no row view is built for cells the block will not see');
	is_deeply($hoa->{tgt}, [undef, undef, undef],
		'HoA map_cell: all-undef column comes back untouched');
}

# HoA: the row view the block receives is one hash, refilled per row, rather
# than a fresh one each time -- the shape the AoH and HoH branches already
# have, since those hand the block the row hash itself. A block that keeps the
# reference therefore sees the current row through it, not the row it was
# handed. Asserted so that going back to a per-row hash is a deliberate act.
{
	my $hoa = { tgt => [1, 2, 3], other => ['a', 'b', 'c'] };
	my @seen_live;      # what each kept ref reports *after* the pass
	my @kept;
	my @seen_now;       # what the view said during the row itself
	assign($hoa, tgt => map_cell {
		push @kept, $_[0];
		push @seen_now, $_[0]{other};
		$_ *= 10;
	});
	is_deeply($hoa->{tgt}, [10, 20, 30], 'HoA map_cell: every row still edited');
	is_deeply(\@seen_now, ['a', 'b', 'c'],
		'HoA map_cell: the view is correct for the row being visited');
	@seen_live = map { $_->{other} } @kept;
	is_deeply(\@seen_live, ['c', 'c', 'c'],
		'HoA map_cell: the view is one reused hash, left holding the last row');
}

# Edge cases: empty frames (coderef and arrayref value)
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

# Error paths
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

# A coderef sees list context on every row, not just row 0. Row 0 used to be
# called in list context and the rest in scalar context, so a capture stored
# the digits in row 0 and the match count (1) everywhere else.
{
	my $d = [ map { { s => "a$_" } } 10 .. 13 ];
	assign($d, n => sub { $_->{s} =~ /(\d+)/ });
	is_deeply([ map { $_->{n} } @$d ], [10, 11, 12, 13], 'AoH: capture is the cell on every row');

	my $h = { r1 => { s => 'x7' }, r2 => { s => 'x8' }, r3 => { s => 'x9' } };
	assign($h, n => sub { $_->{s} =~ /(\d)/ });
	is_deeply([ map { $h->{$_}{n} } sort keys %$h ], [7, 8, 9], 'HoH: capture is the cell on every row');

	my $c = { s => ['x7', 'x8', 'x9'] };
	assign($c, n => sub { $_->{s} =~ /(\d)/ });
	is_deeply($c->{n}, [7, 8, 9], 'HoA: capture is the cell on every row');

	# A failed bare match is the empty list in list context, so every miss is
	# undef -- row 0 used to get undef and the others ''.
	my $m = [ { s => 'x' }, { s => 'Dr' }, { s => 'y' } ];
	assign($m, dr => sub { $_->{s} =~ /^Dr/ });
	ok(!defined $m->[0]{dr} && !defined $m->[2]{dr}, 'failed match is undef on row 0 and later rows alike');
	ok($m->[1]{dr}, 'successful match is true');

	throws_ok { assign([ { k => 1 }, { k => 2 } ], x => sub { $_[1] ? (1, 2) : 5 }) }
		qr/'x' returned 2 values for row 1/, 'AoH: a later row returning a list dies';
	throws_ok { assign({ a => { k => 1 }, b => { k => 2 } }, x => sub { $_[1] ? (1, 2, 3) : 5 }) }
		qr/'x' returned 3 values for row 1/, 'HoH: a later row returning a list dies';
	throws_ok { assign({ k => [1, 2] }, x => sub { $_[1] ? (1, 2) : 5 }) }
		qr/'x' returned 2 values for row 1/, 'HoA: a later row returning a list dies';
}

# Writing to $_ inside a per-row coderef replaces the localized copy of the
# row reference, not the row.
{
	my $d = [ { a => 1 }, { a => 2 } ];
	assign($d, b => sub { my $v = $_->{a}; $_ = 'clobbered'; $v * 10 });
	is_deeply($d, [ { a => 1, b => 10 }, { a => 2, b => 20 } ], 'assigning to $_ leaves the frame alone');
}

# HoA/HoH detection looks at every value. It used to look only at whichever
# value values() returned first, so a HoA with a scalar entry worked or died
# depending on hash order.
{
	my $died = 0;
	for my $try (1 .. 50) {
		my %h = (x => [1, 2], u => undef);
		$h{"c$_"} = 'k' for 1 .. 8;
		eval { assign(\%h, y => sub { $_->{x} * 2 . $_->{c1} }); 1 } or $died++;
		if ($try == 1) {
			is_deeply($h{y}, ['2k', '4k'], 'HoA: a scalar entry is passed through to every row view');
		}
	}
	is($died, 0, 'HoA with scalar and undef entries never dies, whatever the hash order');

	throws_ok { assign({ a => [1], b => { k => 1 } }, x => sub { 1 }) }
		qr/mixes array and hash values/, 'a hash of both arrays and hashes dies';
	throws_ok { assign({ bad => 'string' }, x => sub { 1 }) }
		qr/no ARRAY \(HoA\) or HASH \(HoH\) values/, 'a hash of plain scalars dies';
}

# Everything checkable is checked before the first write, so a failing call
# leaves the frame exactly as it found it.
{
	my $d = [ { a => 1 }, { a => 2 }, 'oops' ];
	throws_ok { assign($d, b => [7, 8, 9]) } qr/row 2 is not a hashref/, 'AoH: bad last row dies';
	is_deeply($d, [ { a => 1 }, { a => 2 }, 'oops' ], 'AoH: ...before any row was written');

	my $h = { r1 => { a => 1 }, r2 => 'oops' };
	throws_ok { assign($h, b => sub { 1 }) } qr/row 'r2' is not a hashref/, 'HoH: bad row dies';
	is_deeply($h, { r1 => { a => 1 }, r2 => 'oops' }, 'HoH: ...before any row was written');

	my $e = [ { a => 1 }, { a => 2 } ];
	throws_ok { assign($e, b => sub { 1 }, c => 'notcode') } qr/value for 'c' must be/,
		'AoH: a bad later pair dies';
	is_deeply($e, [ { a => 1 }, { a => 2 } ], 'AoH: ...before the good first pair was applied');
	throws_ok { assign($e, b => sub { 1 }, c => [1]) } qr/column 'c' has 1 values but data frame has 2 rows/,
		'AoH: a short arrayref in a later pair dies';
	is_deeply($e, [ { a => 1 }, { a => 2 } ], 'AoH: ...before the good first pair was applied');

	my $c = { a => [1, 2] };
	throws_ok { assign($c, b => [3, 4], nope => map_cell { $_ = 1 }) } qr/map_cell target column 'nope'/,
		'HoA: map_cell on a missing column after a good pair dies';
	is_deeply($c, { a => [1, 2] }, 'HoA: ...before the good first pair was applied');
	assign($c, b => [3, 4], b => map_cell { $_ *= 10 });
	is_deeply($c->{b}, [30, 40], 'HoA: map_cell may edit a column an earlier pair made');
}

# An empty hash is an empty HoA, and its first arrayref value fixes the row
# count, so a frame can be built up from nothing.
{
	my $h = {};
	assign($h, x => [1, 2, 3], y => sub { $_->{x} * 2 });
	is_deeply($h, { x => [1, 2, 3], y => [2, 4, 6] }, 'empty hash: first arrayref sets the row count');
	throws_ok { assign({}, x => [1, 2, 3], y => [1]) } qr/column 'y' has 1 values but data frame has 3 rows/,
		'empty hash: a later arrayref must match the first';
	my $z = {};
	assign($z, y => sub { 1 });
	is_deeply($z, { y => [] }, 'empty hash: a coderef first makes an empty column');
	throws_ok { assign({}, y => sub { 1 }, x => [1]) } qr/column 'x' has 1 values but data frame has 0 rows/,
		'empty hash: ...which then fixes the row count at 0';
}

# HoA row views alias the frame (LikeR.xs _hoa_assign): one hash for the pass,
# whose values are the frame's own cells.
{
	my $h = { x => [1, 2, 3], lab => 'k' };
	assign($h, y => sub { $_->{x} *= 10; $_->{x} + 1 });
	is_deeply($h->{x}, [10, 20, 30], 'HoA: a write through $_->{col} reaches the frame');
	is_deeply($h->{y}, [11, 21, 31], 'HoA: ...and the block reads its own write');

	assign($h, z => sub { $_->{lab} });
	is_deeply($h->{z}, ['k', 'k', 'k'], 'HoA: a scalar entry is aliased on every row');

	my $s = { long => [1, 2, 3], short => [9] };
	assign($s, w => sub { $_->{short} = 5; 1 });
	is_deeply($s->{short}, [5], 'HoA: writing a missing cell does not grow a short column');

	my @kept;
	assign($s, k => sub { push @kept, $_; 1 });
	is(scalar(@kept), 3, 'HoA: a block may keep the view');
	ok($kept[0] == $kept[1] && $kept[1] == $kept[2], 'HoA: ...which is one hash for the whole pass');

	assign($s, seen => sub { my $was = exists $_->{tmp}; $_->{tmp} = 1; $was ? 1 : 0 });
	is_deeply($s->{seen}, [0, 0, 0], 'HoA: a key the block adds is gone on the next row');
	ok(!exists $s->{tmp}, 'HoA: ...and never reaches the frame');

	assign($s, got => sub { my $v = $_->{long}; delete $_->{long}; $v });
	is_deeply($s->{got}, [1, 2, 3], 'HoA: a key the block deletes is back on the next row');
	is_deeply($s->{long}, [1, 2, 3], 'HoA: ...and deleting it from the view leaves the column');

	my $r = { x => [1, 2, 3] };
	assign($r, y => sub { $r->{x} = ['gone']; $_->{x} });
	is_deeply($r->{y}, [1, 2, 3], 'HoA: replacing a column mid-pass leaves the view on the old one');

	my $a = { x => [4, 5] };
	assign($a, y => sub { my $row = $_[0]; $_ = 'clobbered'; $row->{x} + $_[1] });
	is_deeply($a->{y}, [4, 6], 'HoA: assigning to $_ does not reach $_[0] or the frame');

	my $u = { "\x{394}G" => [1, 2] };
	throws_ok { assign($u, "\x{394}G r" => sub { $_[1] ? (1, 2) : 0 }) }
		qr/'\x{394}G r' returned 2 values for row 1/, 'HoA: the croak keeps a UTF-8 column name';
}

# HoA map_cell: $_ aliases the cell itself.
{
	my $h = { s => ['A:1', undef, 'C:3'], t => [1, 2, 3] };
	my @sib;
	assign($h, s => map_cell { s/^[A-Z]://; push @sib, $_[0]{s} });
	is_deeply($h->{s}, ['1', undef, '3'], 'HoA map_cell: edits in place, skips undef');
	is_deeply(\@sib, ['1', '3'], 'HoA map_cell: the view shows the edited cell');

	my $ro = { s => ['a', 'b'] };
	Internals::SvREADONLY($ro->{s}[0], 1);
	assign($ro, s => map_cell { $_ = uc });
	is_deeply($ro->{s}, ['A', 'B'], 'HoA map_cell: a read-only cell is edited as a copy and stored back');

	my $e = { s => [1, 2, 3] };
	assign($e, s => map_cell { @{ $e->{s} } = () if $_[1] == 0; $_ = 'x' });
	# $_ aliases a cell the block has just removed, so the edit goes with it,
	# and the rows after it have no cell left to visit.
	is_deeply($e->{s}, [], 'HoA map_cell: a block that empties the column does not crash');
}

# A tied frame keeps the perl loop, whose views are copies.
{
	require Tie::Array;
	tie my @col, 'Tie::StdArray';
	@col = (1, 2, 3);
	my $h = { x => \@col };
	assign($h, y => sub { $_->{x} *= 10; $_->{x} });
	is_deeply($h->{y}, [10, 20, 30], 'tied HoA: per-row coderef');
	is_deeply([@col], [1, 2, 3], 'tied HoA: ...writes go to a copy, not the frame');
	assign($h, x => map_cell { $_ += 1 });
	is_deeply([@col], [2, 3, 4], 'tied HoA: map_cell stores back through the tie');
}

# HoA whole-column return is installed as the column.
{
	my $c = { a => [3, 1, 2] };
	assign($c, r => sub { (30, 10, 20) });
	is_deeply($c->{r}, [30, 10, 20], 'HoA: whole-column list becomes the column');
}

# Leak guards (SV-level). Each block builds a throwaway frame so everything
# is freed at block exit; skipped under Devel::Cover.
SKIP: {
	skip 'leak checks skipped under Devel::Cover', 13 if $INC{'Devel/Cover.pm'};

	no_leaks_ok {
		my $d = { x => [1, 2, 3], short => [1], lab => 'k' };
		assign($d, y => sub { $_->{x} *= 2; $_->{short} = 1; $_->{tmp} = 1; delete $_->{lab}; 1 });
	} 'no SV leak: HoA aliased view, with the block adding, deleting and writing keys';

	no_leaks_ok {
		my $d = { x => [1, 2, 3] };
		my @kept;
		assign($d, y => sub { push @kept, $_; 1 });
	} 'no SV leak: HoA view kept by the block';

	no_leaks_ok {
		my $d = { s => ['a', 'b'], t => [1, 2] };
		Internals::SvREADONLY($d->{s}[0], 1);
		assign($d, s => map_cell { $_ = uc });
	} 'no SV leak: HoA map_cell, aliased and read-only cells';

	no_leaks_ok {
		my $d = { x => [1, 2, 3] };
		eval { assign($d, y => sub { die "boom\n" if $_[1] == 1; 1 }) };
		eval { assign($d, y => sub { $_[1] ? (1, 2) : 1 }) };
		eval { assign($d, x => map_cell { die "boom\n" }) };
	} 'no SV leak when a HoA block dies part-way';

	no_leaks_ok {
		my $d = { a => { k => 1 }, b => { k => 2 } };
		assign($d, x => sub { $_->{k} =~ /(\d)/ }, y => [5, 6], k => map_cell { $_++ });
	} 'no SV leak: HoH per-row, arrayref and map_cell';

	no_leaks_ok {
		eval { assign([ { k => 1 }, { k => 2 } ], x => sub { $_[1] ? (1, 2) : 5 }) };
	} 'no SV leak when a later row returns a list';

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
		my $d = [ { s => 'A:1' }, { s => 'B:2' } ];
		assign($d, s => map_cell { s/^[A-Z]:// });
	} 'no SV leak: AoH map_cell in-place edit';

	no_leaks_ok {
		my $d = { s => ['A:1', 'B:2'], k => [1, 2] };
		assign($d, s => map_cell { s/^[A-Z]://; $_ .= $_[0]{k} });
	} 'no SV leak: HoA map_cell in-place edit';

	no_leaks_ok {
		eval { assign([ { a => 1 } ], bad => 'notcode') };
	} 'no SV leak on the croak path';
}

done_testing;
