#!/usr/bin/env perl
# summary() now renders a view()-style, optionally coloured table of per-variable
# statistics via the shared _render_grid(). It accepts every shape view() does
# (flat vector, AoA, HoA, AoH, HoH) and view()'s display options. These tests
# capture the returned string with return_only => 1 (which also suppresses the
# print) and assert on structure, so they hold regardless of the exact numbers
# the XS stat routines produce.
use strict;
use warnings;
use Test::More;
use Test::Exception;
use Stats::LikeR 'summary';

# always capture, never print, and keep the output deterministic (no colour)
sub s_ { return summary(@_, return_only => 1, color => 0) }

# --- flat list of scalars (one vector) ------------------------------------
{
	my $txt = s_(1, 2, 3, 4, 5);
	ok !ref($txt), 'summary returns a string (like view)';
	like $txt, qr/# summary: 1 row x 7 cols/, 'banner reports one summary row';
	like $txt, qr/Median/, 'the statistic columns are present';
	like $txt, qr/Mean/,   'Mean column present';
	unlike $txt, qr/\bIndex\b|\bKey\b|\bColumn\b/,
		'a flat vector has no label column';
}

# --- flat list WITH a trailing named arg (the peel-off while-loop) --------
{
	# nrows must be consumed as an option, NOT counted as data
	is s_(1, 2, 3, nrows => 2), s_(1, 2, 3),
		'trailing nrows is peeled off, not folded into the data';
	is s_(1, 2, 3, nrow => 1), s_(1, 2, 3), 'nrow synonym peeled off too';
	is s_(1, 2, 3, n => 1),    s_(1, 2, 3), 'n synonym peeled off too';
}

# --- array reference of scalars (single vector) ---------------------------
{
	like s_([10, 20, 30, 40]), qr/# summary: 1 row/, 'arrayref of scalars is one vector';
}

# --- array of arrays: one row per inner array, "Index" label --------------
{
	my $txt = s_([ [1, 2, 3, 4], [5, 6, 7, 8] ]);
	like $txt, qr/\bIndex\b/, 'AoA labels rows by Index';
	like $txt, qr/# summary: 2 rows/, 'AoA has one summary row per inner array';
}

# --- hash of arrays: one row per key, "Key" label -------------------------
{
	like s_({ A => [1, 2, 3], B => [4, 5, 6] }), qr/\bKey\b/, 'HoA labels rows by Key';
}

# --- array of hashes: one row per column, "Column" label ------------------
{
	my $txt = s_([ { x => 1, y => 10 }, { x => 2, y => 20 }, { x => 3, y => 30 } ]);
	like $txt, qr/\bColumn\b/, 'AoH labels rows by Column';
	like $txt, qr/# summary: 2 rows/, 'AoH summarises each column';
	like $txt, qr/^x\b/m, 'column x is summarised';
	like $txt, qr/^y\b/m, 'column y is summarised';
}

# --- hash of hashes: one row per column, gathered across rows -------------
{
	my $txt = s_({ r1 => { a => 1, b => 2 }, r2 => { a => 3, b => 4 }, r3 => { a => 5, b => 6 } });
	like $txt, qr/\bColumn\b/, 'HoH labels rows by Column';
	like $txt, qr/# summary: 2 rows/, 'HoH summarises each (inner) column';
	like $txt, qr/^a\b/m, 'HoH column a is summarised';
	like $txt, qr/^b\b/m, 'HoH column b is summarised';
}

# --- non-numeric / undef cells are ignored (no longer a fatal error) ------
{
	my $txt;
	lives_ok { $txt = s_({ r1 => { v => 1, name => 'foo' }, r2 => { v => 3, name => undef } }) }
		'undef / non-numeric values no longer die';
	# the numeric column keeps its 2 values; the all-text column shows 0 + na
	like $txt, qr/^v\s+2\b/m,           'numeric column counts only its numeric values';
	like $txt, qr/^name\s+0\b.*undef/m, 'an all-non-numeric column shows 0 values and na';
}

# --- nrows caps the rows shown and notes the remainder --------------------
{
	my $hoa = { map { ("k$_" => [1 .. 5]) } 1 .. 5 };   # 5 columns
	my $txt = s_($hoa, nrows => 2);
	like $txt, qr/# summary: 5 rows x 7 cols\s+\(showing 2\)/, 'banner shows the cap';
	like $txt, qr/# \.\.\. 3 more rows/, 'a "... N more rows" note is appended';
}

# --- colour: escapes appear only when colour is on ------------------------
{
	my $plain = summary([1, 2, 3], return_only => 1, color => 0);
	my $col   = summary([1, 2, 3], return_only => 1, color => 1);
	unlike $plain, qr/\e\[/, 'color => 0 emits no ANSI escapes';
	like   $col,   qr/\e\[/, 'color => 1 emits ANSI escapes (view-style)';
}

# --- error paths ----------------------------------------------------------
{
	throws_ok { summary(\"scalar-ref", return_only => 1) }
		qr/must either be a hash or an array/, 'die: bad reference type';
	throws_ok { summary([1, 2, 3], bogus => 1) }
		qr/unknown argument/, 'die: unknown option (mirrors view/read_table)';
}

done_testing;
