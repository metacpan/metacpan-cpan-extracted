#!/usr/bin/env perl

require 5.010;
use warnings FATAL => 'all';
use File::Temp;
use Stats::LikeR;
use Test::Exception; # dies_ok
use Test::More;
use Test::LeakTrace 'no_leaks_ok';

# Helpers: read a written .tex file and pick apart its body-only structure.
sub read_tex {
	my ($file) = @_;
	open my $fh, '<', $file or die "read $file: $!";
	local $/;
	my $c = <$fh>;
	close $fh;
	return defined($c) ? $c : '';
}

# Non-comment, non-blank lines (drops the %written-by banner, the
# % \begin{longtable}{...} hint, and any % comments).
sub body_lines {
	my ($c) = @_;
	return grep { length and $_ !~ /^%/ } split /\n/, $c;
}

# The single header line: the only line carrying both \textbf{ and \hline
# (data rows end with \\, and no standalone rule lines are emitted).
sub header_of {
	my ($c) = @_;
	my ($h) = grep { /\\textbf\{/ and /hline/ } split /\n/, $c;
	return $h;
}

# Data rows: lines ending in \\ that are not the header (which ends \\ \hline).
sub data_rows_of {
	my ($c) = @_;
	return grep { /\\\\\s*$/ and $_ !~ /hline/ } split /\n/, $c;
}

# Column count from a rendered row: (number of ' & ' separators) + 1.
sub ncols {
	my ($line) = @_;
	my $seps = () = $line =~ / & /g;
	return $seps + 1;
}

my $dir = File::Temp->newdir; # cleaned up at scope end

# One shape at a time. Each writes a body-only file, then checks it carries
# no tabular wrapper / no column spec but does carry the hint, header, and
# data rows. The body opens with the header row (which ends in \\ \hline) and
# closes with the last data row; no standalone \hline rules are emitted.
sub check_shape {
	my ($name, $data, $exp_rows, $exp_cols) = @_;
	subtest $name => sub {
		my $file = "$dir/$name.tex";
		write_table($data, $file, 'row.names' => 0, 'tex.longtable' => 1);
		my $c = read_tex($file);

		unlike($c, qr/\\begin\{tabular\}/, 'no \begin{tabular}');
		unlike($c, qr/\\end\{tabular\}/,   'no \end{tabular}');
		unlike($c, qr/\{\|/,               'no tabular column spec ({| ... |})');
		unlike($c, qr/^\\hline$/m,         'no standalone \hline rule lines');
		like($c,   qr/^%written by /,      'keeps provenance banner');
		like($c,   qr/^% \\begin\{longtable\}\{/m, 'emits longtable column hint');

		my $h = header_of($c);
		ok(defined($h), 'header row present');
		like($h, qr/\\textbf\{/,       'header cells are \textbf{}');
		like($h, qr/\\\\ \\hline\s*$/, 'header row ends with \\\\ \\hline');
		is(ncols($h), $exp_cols, "header has $exp_cols columns");

		my @rows = data_rows_of($c);
		is(scalar(@rows), $exp_rows, "$exp_rows data rows");

		my @body = body_lines($c);
		is($body[0], $h, 'body opens with the header row');
		if (@rows) {
			is($body[-1], $rows[-1], 'body closes with the last data row (no trailing rule)');
			is(ncols($rows[0]), $exp_cols, "data row has $exp_cols columns");
			like($rows[0], qr/\\\\\s*$/, 'data row ends with \\\\');
		}
		done_testing();
	};
}

check_shape('flat_hash', { alpha => 1, beta => 2, gamma => 3 }, 1, 3);

check_shape('hoh', {
	r1 => { c1 => 'a', c2 => 'b' },
	r2 => { c1 => 'c', c2 => 'd' },
}, 2, 2);

check_shape('hoa', {
	'x' => [1, 2, 3],
	'y' => [4, 5, 6],
}, 3, 2);

check_shape('aoh', [
	{ name => 'foo', val => 10 },
	{ name => 'bar', val => 20 },
], 2, 2);

# AoA: first inner array is consumed as the header, so 3 arrays -> 2 rows.
check_shape('aoa', [
	['h1', 'h2'],
	[1, 2],
	[3, 4],
], 2, 2);

# Equivalence: tex.longtable output differs from a full tabular only in the
# environment wrapper and rules. The header and data rows are byte-identical.
my %data = ( x => [1, 2, 3], y => [4, 5, 6] );
my $full = "$dir/full.tex";
my $long = "$dir/long.tex";
write_table(\%data, $full, 'row.names' => 0, tex => 1);
write_table(\%data, $long, 'row.names' => 0, 'tex.longtable' => 1);
my $cf = read_tex($full);
my $cl = read_tex($long);

like($cf, qr/\\begin\{tabular\}/,   'full form has \begin{tabular}');
unlike($cl, qr/\\begin\{tabular\}/, 'longtable form does not');

is(header_of($cl), header_of($cf), 'identical header row');
is_deeply([data_rows_of($cl)], [data_rows_of($cf)], 'identical data rows');

# tex.longtable implies LaTeX even when the file name / tex flag say otherwise.
my %flat = ( a => 1, b => 2 );

my $txt = "$dir/nodotex.txt"; # not a .tex name
write_table(\%flat, $txt, 'row.names' => 0, 'tex.longtable' => 1);
my $c1 = read_tex($txt);
like($c1, qr/\\textbf\{/, 'non-.tex name still rendered as LaTeX');
unlike($c1, qr/\\begin\{tabular\}/, 'and still body-only');

my $off = "$dir/texoff.txt";
write_table(\%flat, $off, 'row.names' => 0, tex => 0, 'tex.longtable' => 1);
my $c2 = read_tex($off);
like($c2, qr/\\textbf\{/, 'tex => 0 is overridden by tex.longtable');

# tex.col.align shows up only in the copy-paste hint; the rendered header and
# data rows are alignment-independent.
%flat = ( a => 1, b => 2, c => 3 );
my $l = "$dir/align_l.tex";
my $r = "$dir/align_r.tex";
write_table(\%flat, $l, 'row.names' => 0, 'tex.longtable' => 1, 'tex.col.align' => 'l');
write_table(\%flat, $r, 'row.names' => 0, 'tex.longtable' => 1, 'tex.col.align' => 'r');
$cl = read_tex($l);
my $cr = read_tex($r);

like($cl, qr/^% \\begin\{longtable\}\{lll\}$/m, 'l hint shows {lll}');
like($cr, qr/^% \\begin\{longtable\}\{rrr\}$/m, 'r hint shows {rrr}');

is(header_of($cl), header_of($cr), 'identical header regardless of align');
is_deeply([data_rows_of($cl)], [data_rows_of($cr)], 'identical data rows');

# ...and the full tabular still honours alignment in its column spec.
$full = "$dir/align_full.tex";
write_table(\%flat, $full, 'row.names' => 0, tex => 1, 'tex.col.align' => 'l');
like(read_tex($full), qr/\{\|l\|l\|l\|\}/, 'full tabular still emits {|l|l|l|}');

# The other tex.* knobs still apply in longtable mode.
%flat = ( a => 1, b => 2 );
my $file = "$dir/knobs.tex";
write_table(\%flat, $file,
	'row.names'     => 0,
	'tex.longtable' => 1,
	'tex.size'      => '\small',
	'tex.comment'   => ['first note', 'second note'],
);
my $c = read_tex($file);
like($c, qr/^\\small$/m,       'size directive emitted');
like($c, qr/^% first note$/m,  'first comment emitted');
like($c, qr/^% second note$/m, 'second comment emitted');

$file = "$dir/comment_str.tex";
write_table({ a => 1 }, $file,
	'row.names' => 0, 'tex.longtable' => 1, 'tex.comment' => 'solo');
like(read_tex($file), qr/^% solo$/m, 'scalar comment emitted');

$file = "$dir/fmt.tex";
write_table({ v => 3.14159265 }, $file,
	'row.names' => 0, 'tex.longtable' => 1, 'tex.format' => 1);
like(read_tex($file), qr/3\.142/, 'numeric cell formatted with %.4g');

my @aoa = (['c1', 'c2'], ['x', 1], ['y', 2]);
my $on  = "$dir/bold_on.tex";
$off = "$dir/bold_off.tex";
write_table(\@aoa, $on,  'row.names' => 0, 'tex.longtable' => 1); # default on
write_table(\@aoa, $off, 'row.names' => 0, 'tex.longtable' => 1, 'tex.bold.1st.col' => 0);

my ($r_on)  = data_rows_of(read_tex($on));
my ($r_off) = data_rows_of(read_tex($off));
like($r_on,  qr/\\textbf\{x\}/, 'first cell bolded by default');
like($r_off, qr/^x & 1/,        'first cell not bolded when disabled');

# Row-name handling: LaTeX defaults row.names ON, so the body leads with an
# empty header cell and each row with its label.
my %hoh = (
	r1 => { c1 => 'a', c2 => 'b' },
	r2 => { c1 => 'c', c2 => 'd' },
);
$file = "$dir/rownames.tex";
write_table(\%hoh, $file, 'tex.longtable' => 1); # no row.names arg
$c = read_tex($file);
my $h = header_of($c);
like($h, qr/^\\textbf\{\} & /, 'header leads with an empty label cell');
is(ncols($h), 3, 'label column plus c1, c2');
like($c, qr/\\textbf\{r1\} & a & b/, 'r1 row carries its (bolded) label');

# Escaping and Greek mapping still run through the shared cell escaper.
$file = "$dir/escape.tex";
write_table({ 'a_b' => 1 }, $file, 'row.names' => 0, 'tex.longtable' => 1);
like(read_tex($file), qr/a\\_b/, 'underscore escaped in header');

$file = "$dir/greek.tex";
write_table({ "\x{0394}" => 1 }, $file, 'row.names' => 0, 'tex.longtable' => 1);
like(read_tex($file), qr/\\textDelta\{\}/, 'U+0394 -> \textDelta{}');

# Error paths still fire with longtable on.
dies_ok {
	write_table({ 'x' => { 'y' => [1, 2] } }, "$dir/bad.tex", 'tex.longtable' => 1);
} 'nested reference cell croaks in longtable mode';

# No leaks.
my $leak = "$dir/leak.tex";
no_leaks_ok {
	eval {
		write_table(
			{ x => [1, 2, 3], 'y' => [4, 5, 6] },
			$leak, 'row.names' => 0, 'tex.longtable' => 1,
		);
	}
} 'write_table tex.longtable: no memory leaks' unless $INC{'Devel/Cover.pm'};

done_testing();
