#!/usr/bin/env perl

# write_table's LaTeX output: comment lines, '<', the characters left raw on
# purpose, and the output handle on a croak.
#
# These are regression tests built from the reproducers that found them, with
# the bytes frozen here; there is no LaTeX writer in R's or Python's suites to
# take them from.  Each failure was confirmed by compiling the file with
# pdflatex:
#
# - tex_comment => "l1\nl2 \\bad" ended its comment at the newline, and the
#   rest was typeset ("! Undefined control sequence.");
# - a cell "p<0.05" printed as p, an inverted exclamation mark, 0.05, which
#   is what '<' is in LaTeX's default OT1 font encoding;
# - a blessed or overloaded tex_comment was dropped without a word;
# - a croak after the file was opened left its handle open, one per call.

require 5.010;
use strict;
use warnings FATAL => 'all';
use File::Temp;
use Test::More;
use Test::Exception;
use Test::LeakTrace 'no_leaks_ok';
use Stats::LikeR qw(write_table);

my $dir = File::Temp->newdir;
my $seq = 0;
sub texfile { $seq++; return "$dir/t$seq.tex" }
sub slurp {
	my $file = shift;
	open my $fh, '<:raw', $file or die "cannot read $file: $!";
	local $/;
	return <$fh>;
}
# the file after its "%written by" line
sub body {
	my $t = slurp(shift);
	$t =~ s/\A%written by [^\n]*\n//;
	return $t;
}

# ---- every line of tex_comment is a comment ---------------------------
{
	my $f = texfile();
	write_table([['a'], [1]], $f, quiet => 1, tex_comment => "l1\nl2 \\bad\r\nl3\rl4\n");
	is(body($f), "% l1\n% l2 \\bad\n% l3\n% l4\n\\begin{tabular}{|c|} \\hline\n"
		. "\\textbf{a} \\\\ \\hline\n\\textbf{1}\\\\\n\\hline \\end{tabular}\n",
		'LF, CRLF and CR each open a new % line; a trailing break opens none');
	$f = texfile();
	write_table([['a'], [1]], $f, quiet => 1, tex_comment => ["one\ntwo", undef, 'three', '']);
	like(body($f), qr/\A% one\n% two\n% three\n% \n\\begin\{tabular\}/,
		'an array of comments: each element and each line in it; undef skipped, empty kept');
	$f = texfile();
	write_table([['a'], [1]], $f, quiet => 1, tex_longtable => 1, tex_comment => "x\ny");
	like(body($f), qr/\A% x\n% y\n% \\begin\{longtable\}\{c\}\n/, 'the same in a longtable body');
	unlike(slurp($f), qr/^[^%\\]/m, 'no line of the longtable preamble escapes being a comment or a macro');
}

# ---- tex_comment and xlsx_comment: objects are strings -----------------
{
	package Ovl;
	use overload q("") => sub { "overloaded\nline" }, fallback => 1;
}
{
	package Plain;
}
{
	my $f = texfile();
	write_table([['a'], [1]], $f, quiet => 1, tex_comment => bless({}, 'Ovl'));
	like(body($f), qr/\A% overloaded\n% line\n/, 'an overloaded object is stringified, line by line');
	$f = texfile();
	write_table([['a'], [1]], $f, quiet => 1, tex_comment => [bless({}, 'Ovl')]);
	like(body($f), qr/\A% overloaded\n% line\n/, '... as an array element too');
	$f = texfile();
	write_table([['a'], [1]], $f, quiet => 1, tex_comment => bless([], 'Plain'));
	like(body($f), qr/\A% Plain=ARRAY\(0x[0-9a-f]+\)\n/, 'a blessed array is an object, and stringified');
	throws_ok { write_table([['a']], texfile(), quiet => 1, tex_comment => {}) }
		qr/^write_table: 'tex_comment' must be a string or an ARRAY reference/, 'an unblessed hash dies';
	throws_ok { write_table([['a']], "$dir/x.xlsx", quiet => 1, xlsx_comment => sub { 1 }) }
		qr/^write_table: 'xlsx_comment' must be a string or an ARRAY reference/, 'xlsx_comment: an unblessed code ref dies';
	my $kept = texfile();
	write_table([['old']], $kept, quiet => 1, tex => 0);
	eval { write_table([['a']], $kept, quiet => 1, tex_comment => {}) };
	is(slurp($kept), "old\n", '... before the file is opened');
  SKIP: {
		skip 'IO::Uncompress::Unzip (core) not available', 1
			unless eval { require IO::Uncompress::Unzip; 1 };
		my $x = "$dir/c.xlsx";
		write_table([['a'], [1]], $x, quiet => 1, xlsx_comment => bless({}, 'Ovl'));
		my $z = IO::Uncompress::Unzip->new($x, Name => 'docProps/core.xml');
		my ($core, $buf) = ('', '');
		$core .= $buf while $z->read($buf) > 0;
		like($core, qr{\noverloaded\nline</dc:description>}, 'xlsx_comment: an overloaded object is stringified');
	}
}

# ---- '<' is escaped as '>' is; \ $ { } ^ ~ stay raw LaTeX -------------
{
	my $f = texfile();
	write_table([['p'], ['p<0.05'], ['a>b'], ['$x^2$ \textit{y} a~b']], $f,
		quiet => 1, tex_bold_1st_col => 0);
	is(body($f), "\\begin{tabular}{|c|} \\hline\n\\textbf{p} \\\\ \\hline\n"
		. "p\\textless{}0.05\\\\\na\\textgreater{}b\\\\\n\$x^2\$ \\textit{y} a~b\\\\\n"
		. "\\hline \\end{tabular}\n",
		"'<' becomes \\textless{}; math and macros pass through");
	$f = texfile();
	write_table([['h'], [chr(0x0394) . '<' . chr(0x03B1)]], $f, quiet => 1, tex_bold_1st_col => 0);
	like(body($f), qr/\\textDelta\{\}\\textless\{\}\\textalpha\{\}/, "'<' in a UTF-8 cell too");
	$f = texfile();
	write_table([['<h>'], [1]], $f, quiet => 1);
	like(body($f), qr/\\textbf\{\\textless\{\}h\\textgreater\{\}\}/, "'<' in a header cell");
}

# ---- the handle is closed when a croak follows the open ----------------
SKIP: {
	skip 'counts open file descriptors through /proc/self/fd', 1 unless -d '/proc/self/fd';
	no warnings 'redefine';
	require Cwd;
	# the provenance line calls Cwd::getcwd() after the file is open
	local *Cwd::getcwd = sub { die "boom\n" };
	opendir my $dh, '/proc/self/fd' or skip 'cannot read /proc/self/fd', 1;
	my $before = () = readdir $dh;
	for (1 .. 5) { eval { write_table([['a'], [1]], texfile(), quiet => 1) } }
	rewinddir $dh;
	my $after = () = readdir $dh;
	is($after, $before, 'five croaks after the open leave no handle open');
}

no_leaks_ok {
	my $f = texfile();
	eval { write_table([['a'], ['p<0.05']], $f, quiet => 1, tex_comment => ["x\ny", bless({}, 'Ovl')]) };
} 'no leaks: comments and escaping' unless $INC{'Devel/Cover.pm'};

done_testing();
