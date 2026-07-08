#!/usr/bin/env perl

require 5.010;
use warnings FATAL => 'all';
use File::Temp;
use Stats::LikeR;
use Test::More;
use Test::LeakTrace 'no_leaks_ok';

my $dir = File::Temp->newdir;
my $seq = 0;
sub texfile {
	$seq++;
	return "$dir/t$seq.tex";
}
sub slurp {
	my $file = shift;
	open my $fh, '<', $file or die "cannot read $file: $!";
	local $/;
	return <$fh>;
}
# index()-based containment checks avoid backslash-escaping headaches.
sub has {
	my ($hay, $needle, $name) = @_;
	ok(index($hay, $needle) != -1, $name) or diag("    missing substring: $needle");
}
sub lacks {
	my ($hay, $needle, $name) = @_;
	ok(index($hay, $needle) == -1, $name) or diag("    unexpected substring: $needle");
}
# The first line is a "%written by ..." provenance comment; strip it.
sub body_after_provenance {
	my $t = shift;
	$t =~ s/\A%written by [^\n]*\n//;
	return $t;
}
# The raw UTF-8 bytes write_table emits for a Unicode string (the .tex file is
# read back as bytes, so pass-through characters must be matched byte-for-byte).
sub utf8_bytes {
	my $s = shift;
	utf8::encode($s);
	return $s;
}

# Every code point handled by tex_greek_macro(), in table order, paired with
# the exact textgreek macro it must produce. Kept in lock-step with the C
# switch in region1_helpers.xs (\usepackage{textgreek} in the document).
# chr() is used so the cells are UTF-8-flagged (all are > U+00FF), which is
# what selects the code-point path -- no "use utf8" or source encoding needed.
my @greek = (
	[0x0391, '\textAlpha'],  [0x0392, '\textBeta'],  [0x0393, '\textGamma'],
	[0x0394, '\textDelta'],  [0x0395, '\textEpsilon'],  [0x0396, '\textZeta'],
	[0x0397, '\textEta'],  [0x0398, '\textTheta'],  [0x0399, '\textIota'],
	[0x039A, '\textKappa'],  [0x039B, '\textLambda'],  [0x039C, '\textMu'],
	[0x039D, '\textNu'],  [0x039E, '\textXi'],  [0x039F, '\textOmikron'],
	[0x03A0, '\textPi'],  [0x03A1, '\textRho'],  [0x03A3, '\textSigma'],
	[0x03A4, '\textTau'],  [0x03A5, '\textUpsilon'],  [0x03A6, '\textPhi'],
	[0x03A7, '\textChi'],  [0x03A8, '\textPsi'],  [0x03A9, '\textOmega'],
	[0x03B1, '\textalpha'],  [0x03B2, '\textbeta'],  [0x03B3, '\textgamma'],
	[0x03B4, '\textdelta'],  [0x03B5, '\textepsilon'],  [0x03B6, '\textzeta'],
	[0x03B7, '\texteta'],  [0x03B8, '\texttheta'],  [0x03B9, '\textiota'],
	[0x03BA, '\textkappa'],  [0x03BB, '\textlambda'],  [0x03BC, '\textmu'],
	[0x03BD, '\textnu'],  [0x03BE, '\textxi'],  [0x03BF, '\textomikron'],
	[0x03C0, '\textpi'],  [0x03C1, '\textrho'],  [0x03C2, '\textvarsigma'],
	[0x03C3, '\textsigma'],  [0x03C4, '\texttau'],  [0x03C5, '\textupsilon'],
	[0x03C6, '\textphi'],  [0x03C7, '\textchi'],  [0x03C8, '\textpsi'],
	[0x03C9, '\textomega'],
);

#--------
# every mapped code point -> its exact macro, in one table (one row each)
#--------
{
	my $tex = texfile();
	my @rows = (['g']);                       # first inner array = header
	push @rows, [chr($_->[0])] for @greek;
	write_table(\@rows, $tex, 'row.names' => 0);
	my $body = body_after_provenance(slurp($tex));
	for my $g (@greek) {
		my ($cp, $macro) = @$g;
		# bold first column (default) wraps each data cell: \textbf{MACRO{}}
		has($body, '\textbf{' . $macro . '{}}', sprintf('U+%04X -> %s', $cp, $macro));
	}
	my @data = grep { /\\textbf\{\\text/ } split /\n/, $body;
	is(scalar(@data), scalar(@greek), 'one mapped data row per Greek code point');
}

#--------
# ASCII actives inside a UTF-8 cell still escape (code-point path, ASCII branch)
#--------
{
	my $tex = texfile();
	my $cell = chr(0x0394) . '_' . chr(0x03B1) . '>' . '&';
	write_table([['h'], [$cell]], $tex, 'tex.bold.1st.col' => 0, 'row.names' => 0);
	has(body_after_provenance(slurp($tex)),
		'\textDelta{}\_\textalpha{}\textgreater{}\&',
		'ASCII # _ % & > are escaped alongside Greek in a UTF-8 cell');
}

#--------
# the {} boundary: Greek followed by a letter must not glue into one macro
#--------
{
	my $tex = texfile();
	write_table([['h'], [chr(0x0394) . 'G']], $tex,
		'tex.bold.1st.col' => 0, 'row.names' => 0);
	my $body = body_after_provenance(slurp($tex));
	has($body,  '\textDelta{}G', 'Greek + letter: {} terminates the control word');
	lacks($body, '\textDeltaG',  'Greek + letter: not glued into \textDeltaG');
}

#--------
# the header call site maps Greek too (not just data cells)
#--------
{
	my $tex = texfile();
	write_table([[chr(0x03A9) . '-total'], ['x']], $tex, 'row.names' => 0);
	has(body_after_provenance(slurp($tex)), '\textbf{\textOmega{}-total}',
		'Greek in a header cell is mapped and bold');
}

#--------
# both sigma forms are distinct (final vs medial)
#--------
{
	my $tex = texfile();
	write_table([['h'], [chr(0x03C2)], [chr(0x03C3)]], $tex,
		'tex.bold.1st.col' => 0, 'row.names' => 0);
	my $body = body_after_provenance(slurp($tex));
	has($body, '\textvarsigma{}', 'U+03C2 -> \textvarsigma (final sigma)');
	has($body, '\textsigma{}',    'U+03C3 -> \textsigma (medial sigma)');
}

#--------
# non-Greek multibyte characters pass through unchanged
#--------
{
	my $tex = texfile();
	# U+2206 INCREMENT looks like a triangle but is NOT Greek Delta;
	# U+00E9 is an accented Latin letter. Both are UTF-8, neither is mapped.
	my $cell = chr(0x2206) . chr(0x00E9);
	write_table([['h'], [$cell]], $tex, 'tex.bold.1st.col' => 0, 'row.names' => 0);
	my $body = body_after_provenance(slurp($tex));
	has($body, utf8_bytes(chr(0x2206)), 'U+2206 passes through as raw UTF-8');
	has($body, utf8_bytes(chr(0x00E9)), 'U+00E9 passes through as raw UTF-8');
	lacks($body, '\textDelta', 'U+2206 is not mistaken for Greek Delta');
}

#--------
# a pure-ASCII cell takes the byte path and still escapes every active char
#--------
{
	my $tex = texfile();
	write_table([['v'], ['a_b>c#d%e&f']], $tex,
		'tex.bold.1st.col' => 0, 'row.names' => 0);
	has(body_after_provenance(slurp($tex)),
		'a\_b\textgreater{}c\#d\%e\&f',
		'pure-ASCII cell: byte path escapes # _ % & >');
}

#--------
# \includesvg{...svg} still passes through verbatim (escaper early-out)
#--------
{
	my $tex = texfile();
	write_table([['fig'], ['\includesvg{a_b.svg}']], $tex,
		'tex.bold.1st.col' => 0, 'row.names' => 0);
	my $body = body_after_provenance(slurp($tex));
	has($body, '\includesvg{a_b.svg}', 'includesvg cell passes through verbatim');
	lacks($body, 'a\_b.svg', 'includesvg: underscore inside is NOT escaped');
}

#--------
# leak safety (an earlier tex write has already loaded Cwd for the provenance
# line, so its one-time allocation is not mistaken for a leak here)
#--------
no_leaks_ok {
	my $tex = texfile();
	my @rows = (['g']);
	push @rows, [chr($_->[0])] for @greek;
	eval { write_table(\@rows, $tex, 'row.names' => 0) }
} 'write_table(tex): no leaks writing every Greek code point' unless $INC{'Devel/Cover.pm'};

no_leaks_ok {
	my $tex = texfile();
	eval {
		write_table([['h'], [chr(0x0394) . '_' . chr(0x03B1) . '>']], $tex,
			'tex.bold.1st.col' => 0, 'row.names' => 0)
	}
} 'write_table(tex): no leaks on a mixed Greek/ASCII UTF-8 cell' unless $INC{'Devel/Cover.pm'};

done_testing();
