#!/usr/bin/env perl

require 5.010;
use warnings FATAL => 'all';
use Stats::LikeR;
use Test::Exception; # die_ok
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

# keep single-block layout deterministic for the non-chunking tests
$ENV{COLUMNS} = 1000;

# split a returned view() string into lines (no trailing-empty artifacts)
sub _lines { split /\n/, $_[0] }
# body lines = everything that is not a banner/footer ('#') line
sub _body  { grep { $_ !~ /^#/ } _lines($_[0]) }

#
# ASSUMPTIONS about AoA rendering conventions (edit here if view differs):
#   * banner tag is "AoA"
#   * columns are headed by their 0-based array index (0, 1, 2, ...)
#   * short rows are padded to the widest row with the na placeholder
# The value / alignment / option tests below do not depend on these.
#

#--------
# basic AoA: banner reports rows x cols, all cells rendered in order
#--------
{
	my $aoa = [ [1, 2, 3], [4, 5, 6] ];
	my $s = view($aoa, return_only => 1, color => 0);
	like $s, qr/^# AoA: 2 rows x 3 cols/, 'AoA banner: N rows x M cols';
	like $s, qr/\(showing 2\)/,           'AoA banner: showing count';

	my @b = _body($s);
	is scalar(@b), 3, 'header + 2 data rows';
	like $b[0], qr/(?<!\d)0(?!\d).*(?<!\d)1(?!\d).*(?<!\d)2(?!\d)/,
		'header row shows 0-based array indices';
	like $b[1], qr/\b1\b.*\b2\b.*\b3\b/, 'first data row: values in order';
	like $b[2], qr/\b4\b.*\b5\b.*\b6\b/, 'second data row: values in order';
}

#--------
# alignment: numeric right-justified, string left-justified => every body
# line ends up the same display width (color off so length == display width)
#--------
{
	my $aoa = [ [5, 'x'], [1000, 'yyy'] ];
	my $s = view($aoa, return_only => 1, color => 0);
	my @b = _body($s);
	my %w = map { length($_) => 1 } @b;
	is scalar(keys %w), 1, 'all body lines share one fixed width';
	like $s, qr/\s5\b/,  'short numeric value is right-padded (leading space)';
	like $s, qr/\bx\s/,  'short string value is left-padded (trailing space)';
}

#--------
# undef cell -> default "undef" placeholder; na overrides it
#--------
{
	my $aoa = [ [1, undef] ];
	my $s = view($aoa, return_only => 1, color => 0);
	like   $s, qr/\bundef\b/, 'undef cell -> "undef" placeholder by default';
	unlike $s, qr/\bNA\b/,    'not shown as NA by default';

	like view($aoa, na => 'NA', return_only => 1, color => 0),
		qr/\bNA\b/, "na => 'NA' overrides the placeholder";
}

#--------
# ragged rows: short rows padded to the widest row with the na placeholder
#--------
{
	my $aoa = [ [1, 2, 3], [4] ];
	my $s = view($aoa, na => 'NA', return_only => 1, color => 0);
	like $s, qr/^# AoA: 2 rows x 3 cols/, 'banner counts the widest row';
	my @b = _body($s);
	like $b[2], qr/\b4\b.*\bNA\b.*\bNA\b/, 'missing cells rendered as na';
}

#--------
# control chars inside a cell are escaped so a record stays one display line
#--------
{
	my $aoa = [ [ "a\tb\nc\rd" ] ];
	my $s = view($aoa, return_only => 1, color => 0);
	like $s, qr/a\\tb\\nc\\rd/, 'tab/newline/cr escaped in-cell';
	is scalar(_body($s)), 2, 'escaped record stays a single line (header + 1 row)';
}

#--------
# max_width truncation + custom ellipsis
#--------
{
	my $aoa = [ [ 'abcdefghij' ] ];                    # 10 chars
	like view($aoa, max_width => 5, return_only => 1, color => 0),
		qr/ab\.\.\./, 'max_width truncates with default ellipsis';
	like view($aoa, max_width => 6, ellipsis => '~', return_only => 1, color => 0),
		qr/abcde~/, 'custom ellipsis honoured';
}

#--------
# n => limits the visible rows and prints the truncation footer once
#--------
{
	my $aoa = [ [1], [2], [3] ];
	my $s = view($aoa, n => 1, return_only => 1, color => 0);
	like $s, qr/\(showing 1\)/,       'n=1: banner shows 1';
	is scalar(grep { /^# \.\.\./ } _lines($s)), 1, 'row-truncation footer printed once';
	is scalar(_body($s)), 2, 'header + a single data row';
}

#--------
# return_only suppresses printing; default path prints; to => FH redirects
#--------
{
	my $aoa = [ [1, 2] ];

	my $out = '';
	{
		open my $old, '>&', \*STDOUT or die $!;
		close STDOUT;
		open STDOUT, '>', \$out or die $!;
		my $r = view($aoa, return_only => 1, color => 0);
		open STDOUT, '>&', $old or die $!;
		ok length($r), 'return_only still returns the string';
	}
	is $out, '', 'return_only prints nothing to STDOUT';

	my $buf = '';
	open my $fh, '>', \$buf or die $!;
	my $ret = view($aoa, to => $fh, color => 0);
	close $fh;
	like $buf, qr/^# AoA:/, 'to => FH writes to the handle';
	is $ret, $buf, 'returned string equals what was printed';
}

#--------
# R-style column chunking still applies to AoA under a narrow width
#--------
{
	my $wide = [ [ 1 .. 8 ], [ 11 .. 18 ] ];
	my $one  = view($wide, width => 1000, return_only => 1, color => 0);
	my $many = view($wide, width => 16,   return_only => 1, color => 0);

	is scalar(grep { /^# AoA:/ } _lines($one)),  1, 'banner printed once (single block)';
	is scalar(grep { /^# AoA:/ } _lines($many)), 1, 'banner printed once (chunked)';
	like $one,  qr/x 8 cols/, 'banner counts every column';
	like $many, qr/x 8 cols/, 'chunked banner still counts every column';
	cmp_ok scalar(_lines($many)), '>', scalar(_lines($one)),
		'a narrow width splits columns into multiple blocks (more lines)';
	is scalar(grep { $_ eq '' } _lines($many)), 0, 'no blank line between blocks';
}

#--------
# AoH detection is unaffected: first element a hashref still reads as AoH
#--------
{
	my $aoh = [ { a => 1, b => 2 } ];
	like view($aoh, return_only => 1, color => 0), qr/^# AoH:/,
		'arrayref of hashrefs still detected as AoH, not AoA';
}

#--------
# errors
#--------
throws_ok { view("not a ref", return_only => 1) }
	qr/ARRAY .* or HASH/, 'scalar input dies with a clear message';

#--------
# memory safety
#--------
no_leaks_ok {
	eval { view([ [1, 2, 3], [4, 5, 6] ], return_only => 1, color => 0) }
} 'view() AoA: no memory leaks' unless $INC{'Devel/Cover.pm'};

no_leaks_ok {
	eval { view([ [1, 2], [3] ], na => 'NA', return_only => 1, color => 0) }
} 'view() AoA ragged: no memory leaks' unless $INC{'Devel/Cover.pm'};

no_leaks_ok {
	eval { view([ [1 .. 8], [11 .. 18] ], width => 16, return_only => 1, color => 0) }
} 'view() AoA chunked: no memory leaks' unless $INC{'Devel/Cover.pm'};

#--------
# row labels are 0-based indexes (Perl-style), not 1-based counts (R-style).
# String cell values keep the leading label digit unambiguous.
#--------
{
	my $aoa = [ ['a'], ['b'], ['c'] ];
	my @b = _body(view($aoa, return_only => 1, color => 0));
	like $b[1], qr/^0\b/, 'first data row is labelled 0 (0-based index)';
	like $b[2], qr/^1\b/, 'second data row is labelled 1';
	like $b[3], qr/^2\b/, 'third data row is labelled 2';

	# an explicit integer row.names still overrides the auto 0-based label
	my $lab = [ [10, 'x'], [20, 'y'] ];
	my @c = _body(view($lab, 'row.names' => 0, return_only => 1, color => 0));
	like $c[1], qr/^10\b/, 'row.names => 0 uses column 0 as the label, not the index';
	like $c[2], qr/^20\b/, 'second explicit label taken from the named column';

	no_leaks_ok {
		eval { view([ ['a'], ['b'], ['c'] ], return_only => 1, color => 0) }
	} 'view() AoA 0-based labels: no memory leaks' unless $INC{'Devel/Cover.pm'};
}

done_testing();
