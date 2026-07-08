#!/usr/bin/env perl
require 5.010;
use warnings FATAL => 'all';
use Stats::LikeR;
use Test::Exception; # die_ok
use Test::More;
use Test::LeakTrace 'no_leaks_ok';

# Column chunking depends on the terminal width (explicit 'width' arg, then
# $ENV{COLUMNS}, then 80). Pin COLUMNS wide so the single-block layout tests
# are deterministic regardless of the caller's terminal; the chunking tests
# below pass an explicit 'width' that overrides it.
$ENV{COLUMNS} = 1000;

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

#--------
# helpers
#--------
sub _strip { my $s = shift; $s =~ s/\e\[[0-9;]*m//g; return $s; }
sub _lines { return split /\n/, _strip($_[0]); }
sub _dwidth { my $s = _strip(shift); utf8::decode($s); return length $s; }

# A table wider than the terminal, reused by the chunking / leak tests below.
# 8 data columns (each 2 wide) + a row_name label column (8 wide), gap = 2.
my $wide = [
	{ row_name => 'r1', c1=>11, c2=>12, c3=>13, c4=>14, c5=>15, c6=>16, c7=>17, c8=>18 },
	{ row_name => 'r2', c1=>21, c2=>22, c3=>23, c4=>24, c5=>25, c6=>26, c7=>27, c8=>28 },
];

#--------
# undefined values render as "undef" (Data::Printer style)
#--------
{
	my $d = [ { a => 1, b => undef }, { a => undef, b => 2 } ];
	my $out = view($d, return_only => 1, color => 0);
	like($out,	 qr/\bundef\b/, 'undefined values render as the bareword "undef"');
	unlike($out, qr/\bNA\b/,	'undefined values are not shown as "NA" by default');
	my $over = view($d, return_only => 1, color => 0, na => 'NA');
	like($over,	  qr/\bNA\b/,	 "na => 'NA' overrides the placeholder");
	unlike($over, qr/\bundef\b/, "na override replaces 'undef' entirely");
	# undef also covers a missing key (HoH/AoH sparse rows)
	my $sparse = [ { a => 1 }, { a => 2, b => 9 } ];
	like(view($sparse, return_only=>1, color=>0), qr/\bundef\b/, 'missing key shows as undef');
}

#--------
# AoH structure
#--------
{
	my $aoh = [
		{ id => 1,	name => 'Alice', score => 9.5	},
		{ id => 2,	name => 'Bob',	 score => 12.25 },
		{ id => 30, name => 'Cara',	 score => 100	},
	];
	my @L = _lines(view($aoh, return_only => 1, color => 0));
	is(scalar @L, 5, 'AoH: summary + header + 3 data rows');
	like($L[0], qr/^# AoH: 3 rows x 3 cols	\(showing 3\)$/, 'AoH summary line');
	like($L[1], qr/id.*name.*score/, 'header lists columns in sorted order');
	like($L[2], qr/^0\b/,	 'row 0 labelled 0');
	like($L[2], qr/Alice/,	 'row 1 carries its data');
	like($L[4], qr/^2\b/,	 'row 2 labelled 2');
}

#--------
# HoA structure
#--------
{
	my $hoa = { id => [1, 2, 30], name => ['Alice', 'Bob', 'Cara'] };
	my @L = _lines(view($hoa, return_only => 1, color => 0));
	like($L[0], qr/^# HoA: 3 rows x 2 cols/, 'HoA summary line');
	like($L[2], qr/^0\b.*Alice/, 'HoA row 0');
}

#--------
# HoH structure (row labels are the outer keys, sorted)
#--------
{
	my $hoh = { beta => { x => 2, y => 'q' }, alpha => { x => 1, y => 'p' } };
	my @L = _lines(view($hoh, return_only => 1, color => 0));
	like($L[0], qr/^# HoH: 2 rows x 2 cols/, 'HoH summary line');
	like($L[1], qr/^row_name/, 'HoH label header is row_name');
	like($L[2], qr/^alpha\b/,  'HoH rows sorted by key (alpha first)');
	like($L[3], qr/^beta\b/,   'HoH second row beta');
}

#--------
# flat hash (single row)
#--------
{
	my @L = _lines(view({ alpha => 1, beta => 'two', gamma => 3.5 }, return_only => 1, color => 0));
	like($L[0], qr/^# Hash: 1 row x 3 cols/, 'flat hash single-row summary');
	is(scalar @L, 3, 'flat hash: summary + header + 1 row');
	like($L[2], qr/^0\b/, 'flat hash row labelled 0');
}

#--------
# empty inputs
#--------
{
	like( (_lines(view({}, return_only=>1, color=>0)))[0], qr/^# Hash: 0 rows x 0 cols/, 'empty hash');
	like( (_lines(view([], return_only=>1, color=>0)))[0], qr/^# AoH: 0 rows x 0 cols/,	 'empty AoH');
}

#--------
# every header and row shares one display width (single-block alignment invariant)
#--------
{
	my $aoh = [ { a => 1, b => 'xx', c => 3 }, { a => 22, b => 'y', c => 444 } ];
	my @L = _lines(view($aoh, return_only => 1, color => 0));
	my %w; $w{ _dwidth($_) }++ for @L[1 .. $#L];
	is(scalar keys %w, 1, 'header and all rows share one display width');
}

#--------
# multibyte UTF-8 does not break alignment (the bug this version fixes)
#--------
{
	my $oe = "J\xC3\xB8rgensen";   # o-slash as 2 UTF-8 bytes
	my $d  = [ { n => 1, who => $oe, z => 'x' }, { n => 22, who => 'Bo', z => 'y' } ];
	my @L  = _lines(view($d, return_only => 1, color => 0));
	my %w; $w{ _dwidth($_) }++ for @L[1 .. $#L];
	is(scalar keys %w, 1, 'a multibyte cell keeps columns aligned');
	my ($oe_line) = grep { /gensen/ } @L;
	isnt(length $oe_line, _dwidth($oe_line), 'the UTF-8 row is wider in bytes than in display columns');
}

#--------
# numeric columns right-align, string columns left-align
#--------
{
	my @N = _lines(view({ x => [1, 100] },	   return_only => 1, color => 0));
	ok($N[2] =~ /\s\s+1$/, 'numeric column right-aligned (short value padded on the left)');
	my @S = _lines(view({ x => ['a', 'ccc'] }, return_only => 1, color => 0));
	ok($S[2] =~ /a\s\s+$/, 'string column left-aligned (short value padded on the right)');
}

#--------
# n / rows, footer, and their validation
#--------
{
	my $aoh = [ map { { i => $_ } } 1 .. 5 ];
	my @L = _lines(view($aoh, n => 2, return_only => 1, color => 0));
	like($L[0],	 qr/showing 2/,			   'n => 2 shows two rows');
	like($L[-1], qr/^# \.\.\. 3 more rows$/, 'footer reports remaining rows');
	is(scalar(grep { /^\d/ } @L), 2, 'exactly two data rows shown');

	my @R = _lines(view($aoh, rows => 2, return_only => 1, color => 0));
	is_deeply(\@R, \@L, "'rows' is a synonym for 'n'");

	throws_ok { view($aoh, n => 1, rows => 1, return_only => 1) }
		qr/either 'n' or 'rows', not both/, 'n + rows together dies';
	throws_ok { view($aoh, n => 'x', return_only => 1) }
		qr/non-negative integer/, 'a non-integer n dies';

	my @Z = _lines(view($aoh, n => 0, return_only => 1, color => 0));
	is(scalar(grep { /^\d/ } @Z), 0, 'n => 0 shows no data rows');
	like($Z[0],	 qr/showing 0/,	   'n => 0 summary says showing 0');
	like($Z[-1], qr/5 more rows/,  'n => 0 still reports all rows in the footer');
	like($Z[1],	 qr/\bi\b/,		   'header still lists columns when showing 0 rows');
}

#--------
# column selection (cols / columns) preserves order and drops the rest
#--------
{
	my $aoh = [ { a => 1, b => 2, c => 3 } ];
	my @L = _lines(view($aoh, cols => ['c', 'a'], return_only => 1, color => 0));
	like($L[0],	  qr/2 cols/,	'cols limits the column count');
	like($L[1],	  qr/c.*a/,		'cols preserves the given order');
	unlike($L[1], qr/\bb\b/,	'an unlisted column is omitted');
	my @L2 = _lines(view($aoh, columns => ['c', 'a'], return_only => 1, color => 0));
	is_deeply(\@L2, \@L, "'columns' is an alias for 'cols'");
}

#--------
# row labels: auto row_name, explicit row.names, and precedence
#--------
{
	my $aoh = [ { row_name => 'r1', v => 10 }, { row_name => 'r2', v => 20 } ];
	my @L = _lines(view($aoh, return_only => 1, color => 0));
	like($L[1], qr/^row_name/, 'a row_name column becomes the label header');
	like($L[2], qr/^r1\b/,	   'first label is r1');
	like($L[2], qr/\b10\b/,	   'the row_name column is not also shown as data twice');

	my $aoh2 = [ { k => 'A', v => 1 } ];
	my @L2 = _lines(view($aoh2, 'row.names' => 'k', return_only => 1, color => 0));
	like($L2[1], qr/^k\b/, "row.names => 'k' uses k as the label column");
	like($L2[2], qr/^A\b/, 'label value taken from k');

	my @L3 = _lines(view($aoh2, 'row.names' => 'k', row_names => 'v', return_only => 1, color => 0));
	is_deeply(\@L3, \@L2, 'row.names takes precedence over row_names');
}

#--------
# max_width truncation is char-aware, with a configurable ellipsis
#--------
{
	my @L = _lines(view({ s => ['abcdefghij'] }, max_width => 5, return_only => 1, color => 0));
	like($L[2], qr/ab\.\.\.$/, 'cell truncated to max_width with the default ellipsis');
	my @E = _lines(view({ s => ['abcdefghij'] }, max_width => 5, ellipsis => '~', return_only => 1, color => 0));
	like($E[2], qr/abcd~$/, 'a custom ellipsis is honoured');
}

#--------
# gap widens the inter-column spacing
#--------
{
	my $aoh = [ { a => 1, b => 2 } ];
	my $g0 = view($aoh, gap => 0, return_only => 1, color => 0);
	my $g3 = view($aoh, gap => 3, return_only => 1, color => 0);
	ok(length($g3) > length($g0), 'a larger gap produces wider output');
}

#--------
# argument and type errors
#--------
{
	my $aoh = [ { a => 1 } ];
	throws_ok { view($aoh, bogus => 1, return_only => 1) } qr/unknown argument/,			'an unknown argument dies';
	throws_ok { view('scalar') }						   qr/expected an ARRAY.*or HASH/,	'a non-reference dies';
	throws_ok { view(\my $x) }							   qr/expected an ARRAY.*or HASH/,	'a scalar reference dies';
}

#--------
# 'width' argument: accepted, and validated as a positive integer
#--------
{
	lives_ok  { view($wide, width => 80,  return_only => 1, color => 0) } "a valid 'width' is accepted (not an unknown arg)";
	throws_ok { view($wide, width => 0,	  return_only => 1) } qr/width.*positive integer/, 'width => 0 dies';
	throws_ok { view($wide, width => -1,  return_only => 1) } qr/width.*positive integer/, 'a negative width dies';
	throws_ok { view($wide, width => 'x', return_only => 1) } qr/width.*positive integer/, 'a non-numeric width dies';
	throws_ok { view($wide, width => 2.5, return_only => 1) } qr/width.*positive integer/, 'a non-integer width dies';
}

#--------
# R-style column chunking: a table wider than the terminal is split into
# successive column blocks, each led by a repeated copy of the label column.
#--------
{
	# wide enough -> a single block
	my @one = _lines(view($wide, width => 1000, return_only => 1, color => 0));
	is(scalar(grep { /^row_name/ } @one), 1, 'width=1000: a single column block');
	like($one[0], qr/x 8 cols/, 'the banner reports the full column count');

	# narrow -> several blocks
	my @narrow = _lines(view($wide, width => 20, return_only => 1, color => 0));
	my @hdr = grep { /^row_name/ } @narrow;
	cmp_ok(scalar @hdr, '>', 1, 'a narrow width splits the columns into multiple blocks');
	is(scalar(grep { /^r1\b/ } @narrow), scalar @hdr, 'the label column is repeated in every block');
	is(scalar(grep { /^# AoH:/ } @narrow), 1, 'the banner is printed exactly once');
	like($narrow[0], qr/x 8 cols/, 'the banner still counts every column, not just one block');

	# every column appears once, in original order, across the blocks
	my @order;
	for my $h (@hdr) { my @t = split ' ', $h; shift @t; push @order, @t; }
	is_deeply(\@order, [qw(c1 c2 c3 c4 c5 c6 c7 c8)],
		'columns are distributed across blocks in their original order');

	# no blank separator line between blocks (matches R)
	is(scalar(grep { $_ eq '' } @narrow), 0, 'no blank line is inserted between blocks');

	# within each block, the header and its rows share one display width
	{
		my @L = _lines(view($wide, width => 24, return_only => 1, color => 0));
		my (@blocks, $cur);
		for my $ln (@L) {
			next if $ln =~ /^#/;						# skip banner / footer
			if ($ln =~ /^row_name/) { $cur = []; push @blocks, $cur; }
			push @$cur, $ln if $cur;
		}
		cmp_ok(scalar @blocks, '>', 1, 'the sample splits into multiple blocks at width 24');
		my $aligned = 1;
		for my $b (@blocks) { my %w; $w{ _dwidth($_) }++ for @$b; $aligned = 0 if keys %w != 1; }
		ok($aligned, 'inside each block the header and its rows share one display width');
	}

	# the row-truncation footer is printed once, not once per block
	my @foot = _lines(view($wide, n => 1, width => 20, return_only => 1, color => 0));
	is(scalar(grep { /^# \.\.\. / } @foot), 1, 'the footer is printed once regardless of block count');

	# a single column wider than the width still renders (overflow, no infinite loop)
	my @big = _lines(view([ { row_name => 'r1', huge => ('X' x 30) } ], width => 10, return_only => 1, color => 0));
	is(scalar(grep { /^row_name/ } @big), 1, 'an over-wide single column stays in one block');
	like($big[1], qr/\bhuge\b/, 'the over-wide column header still shows');
	like($big[2], qr/X{30}/,	'the over-wide value is rendered in full');
}

#--------
# terminal-width source precedence: explicit 'width' > $ENV{COLUMNS} > 80
#--------
{
	{
		local $ENV{COLUMNS} = 18;
		my @L = _lines(view($wide, return_only => 1, color => 0));
		cmp_ok(scalar(grep { /^row_name/ } @L), '>', 1, 'COLUMNS drives chunking when no width is given');
	}
	{
		local $ENV{COLUMNS} = 18;
		my @L = _lines(view($wide, width => 1000, return_only => 1, color => 0));
		is(scalar(grep { /^row_name/ } @L), 1, 'an explicit width overrides COLUMNS');
	}
	{
		local $ENV{COLUMNS} = 'not-a-number';
		lives_ok { view($wide, return_only => 1, color => 0) } 'an invalid COLUMNS is ignored rather than fatal';
	}
}

#--------
# colour: opt-in ANSI that never disturbs alignment
#--------
{
	my $aoh	  = [ { a => 1, b => undef } ];
	my $plain = view($aoh, return_only => 1, color => 0);
	my $col	  = view($aoh, return_only => 1, color => 1);
	unlike($plain, qr/\e\[/, 'color => 0 emits no ANSI');
	like($col,	   qr/\e\[/, 'color => 1 emits ANSI');
	(my $stripped = $col) =~ s/\e\[[0-9;]*m//g;
	is($stripped, $plain, 'stripping ANSI reproduces the plain layout exactly');
	like($col, qr/\e\[91mundef\e\[0m/, 'undef painted with the undef colour');
	like($col, qr/\e\[94m/,			   'numbers painted with the number colour');
	like($col, qr/\e\[35m/,			   'headers painted with the hash colour');
	like($col, qr/\e\[96m# AoH/,	   'the caller-info line is painted');
}

#--------
# colour survives chunking: each block's header is still painted
#--------
{
	my $col = view($wide, width => 20, return_only => 1, color => 1);
	my @painted_hdr = grep { /\e\[35m/ && /row_name/ } split /\n/, $col;
	cmp_ok(scalar @painted_hdr, '>', 1, 'every block header is coloured');
	(my $stripped = $col) =~ s/\e\[[0-9;]*m//g;
	is($stripped, scalar view($wide, width => 20, return_only => 1, color => 0),
		'stripping ANSI from a chunked render reproduces the plain chunked layout');
}

#--------
# custom Data::Printer-style colours (hex truecolor)
#--------
{
	my $col = view([ { n => 5 } ], return_only => 1, color => 1, colors => { number => '#87afff' });
	like($col, qr/\e\[38;2;135;175;255m/, 'a #rrggbb colour becomes a truecolor escape');
}

#--------
# 'to' filehandle and return_only
#--------
{
	my $aoh = [ { a => 1 } ];
	open my $fh, '>', \my $buf or die "open: $!";
	my $ret = view($aoh, to => $fh, color => 0);
	close $fh;
	is($buf, $ret, "output sent to a 'to' filehandle equals the returned string");
	ok(length(view($aoh, return_only => 1, color => 0)), 'return_only returns the rendered string');
}

#--------
# memory
#--------
no_leaks_ok {
	my $s = view([ { a => 1, b => 'x', c => undef } ], return_only => 1, color => 0);
} 'view: no memory leaks on a plain render' unless $INC{'Devel/Cover.pm'};

no_leaks_ok {
	my $s = view({ id => [1, 2], name => ["J\xC3\xB8rgensen", 'Bo'] }, return_only => 1, color => 1);
} 'view: no memory leaks on a coloured UTF-8 render' unless $INC{'Devel/Cover.pm'};

# warm up the chunking path before the leak check (hoist the real call out)
view($wide, width => 20, return_only => 1, color => 0);
no_leaks_ok {
	my $s = view($wide, width => 20, return_only => 1, color => 0);
} 'view: no memory leaks on a chunked (multi-block) render' unless $INC{'Devel/Cover.pm'};

#--------
# auto row labels are 0-based indexes (Perl style), not 1-based counts (R style)
#--------
{
	my @A = _lines(view([ { v => 'a' }, { v => 'b' }, { v => 'c' } ], return_only => 1, color => 0));
	like($A[2], qr/^0\b/, 'AoH auto label: first row is 0');
	like($A[3], qr/^1\b/, 'AoH auto label: second row is 1');
	like($A[4], qr/^2\b/, 'AoH auto label: third row is 2');

	my @H = _lines(view({ v => ['a', 'b', 'c'] }, return_only => 1, color => 0));
	like($H[2], qr/^0\b/, 'HoA auto label: first row is 0');
	like($H[3], qr/^1\b/, 'HoA auto label: second row is 1');

	my @Q = _lines(view([ ['a'], ['b'], ['c'] ], return_only => 1, color => 0));
	like($Q[2], qr/^0\b/, 'AoA auto label: first row is 0');
	like($Q[3], qr/^1\b/, 'AoA auto label: second row is 1');

	my @F = _lines(view({ only => 'x' }, return_only => 1, color => 0));
	like($F[2], qr/^0\b/, 'flat hash: single row labelled 0');

	# HoH is unaffected: labels remain the (sorted) outer keys
	my @K = _lines(view({ beta => { x => 1 }, alpha => { x => 2 } }, return_only => 1, color => 0));
	like($K[2], qr/^alpha\b/, 'HoH label unchanged: still the outer key');
	like($K[3], qr/^beta\b/,  'HoH second label is the outer key');

	no_leaks_ok {
		my $s = view([ { v => 'a' }, { v => 'b' } ], return_only => 1, color => 0);
	} 'view: no memory leaks rendering 0-based auto labels' unless $INC{'Devel/Cover.pm'};
}

#--------
# regression: an already-decoded (utf8-flagged) wide char -- e.g. a "ΔG range"
# header written under `use utf8` -- must be encoded to bytes on output, so
# print() never warns "Wide character in print". Warnings are lexically scoped
# to the module, so we trap them here with a __WARN__ handler rather than
# relying on this file's FATAL => 'all'.
#--------
{
	my $hdr = "\xCE\x94G range";   # the UTF-8 bytes for "ΔG range" ...
	utf8::decode($hdr);            # ... promoted to an already-decoded char string
	ok(utf8::is_utf8($hdr), 'the header under test really is utf8-flagged');

	my (@w, $buf);
	$buf = '';
	{
		local $SIG{__WARN__} = sub { push @w, $_[0] };
		open my $fh, '>', \$buf or die "open: $!";
		view([ { $hdr => 'x', v => 1 } ], to => $fh, color => 0);
		close $fh;
	}
	is(scalar(grep { /Wide character/i } @w), 0,
		'no "Wide character in print" warning for a utf8-flagged header');
	ok(length $buf,          'output was written');
	ok(!utf8::is_utf8($buf), 'the rendered string is bytes, not wide chars');
	like($buf, qr/\xCE\x94/, 'the wide char is emitted as its UTF-8 bytes');

	# same again for a wide char in a cell value, not just the header
	my $val = "\xCE\x94"; utf8::decode($val);
	my ($b2, @w2) = ('');
	{
		local $SIG{__WARN__} = sub { push @w2, $_[0] };
		open my $fh2, '>', \$b2 or die "open: $!";
		view([ { g => $val } ], to => $fh2, color => 0);
		close $fh2;
	}
	is(scalar(grep { /Wide character/i } @w2), 0, 'no warning for a utf8-flagged value');
	like($b2, qr/\xCE\x94/, 'wide value emitted as UTF-8 bytes');

	no_leaks_ok {
		my $h = "\xCE\x94"; utf8::decode($h);
		my $s = view([ { $h => 1 } ], return_only => 1, color => 0);
	} 'view: no memory leaks on a utf8-flagged wide char' unless $INC{'Devel/Cover.pm'};
}

done_testing;
