#!/usr/bin/env perl

require 5.010;
use warnings FATAL => 'all';
use File::Temp;
use Stats::LikeR;
use Test::Exception; # throws_ok
use Test::More;
use Test::LeakTrace 'no_leaks_ok';

my $dir = File::Temp->newdir;
my $seq = 0;
# Return a fresh (csv, tex) path pair under the temp dir. LaTeX is now written
# to the *main* file, selected either by a ".tex" name or by tex => 1, so the
# two paths are used to exercise both the auto-detect and the override cases.
sub paths {
	$seq++;
	return ("$dir/t$seq.csv", "$dir/t$seq.tex");
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
# Expected column spec for n columns at the default 'c' alignment.
sub spec {
	my $n = shift;
	return '\begin{tabular}{|' . ('c|' x $n) . '} \hline';
}
# The first line is a "%written by <cwd>/<RealScript>" provenance comment whose
# text is environment-dependent; strip it so the rest can be matched exactly.
sub body_after_provenance {
	my $t = shift;
	$t =~ s/\A%written by [^\n]*\n//;
	return $t;
}

#--------
# byte-exact output (locks the whole format); .tex name auto-selects LaTeX and
# is the single output file (no delimited file is written alongside)
#--------
{
	my ($csv, $tex) = paths();
	write_table([[qw(k v)], ['x', 1], ['y', 2]], $tex, 'row.names' => 0);
	my $expected = <<'END_TEX';
\begin{tabular}{|c|c|} \hline
\textbf{k} & \textbf{v} \\ \hline
\textbf{x} & 1\\
\textbf{y} & 2\\
\hline \end{tabular}
END_TEX
	ok(-e $tex, '.tex name: LaTeX file is created');
	like(slurp($tex), qr/\A%written by /, '.tex name: first line is the provenance comment');
	is(body_after_provenance(slurp($tex)), $expected, '.tex name: AoA output is byte-exact');
	ok(!-e $csv, '.tex name: no separate delimited file is written');
}

#--------
# provenance comment + structural scaffolding
#--------
{
	my ($csv, $tex) = paths();
	write_table([[qw(k v)], ['x', 1]], $tex, 'row.names' => 0);
	my $t = slurp($tex);
	has($t, '%written by ', 'provenance comment is present');
	has($t, spec(2), 'default alignment is c, one cell per column');
	has($t, '\hline \end{tabular}', 'table is closed with \hline \end{tabular}');
	has($t, '\textbf{k}', 'header cells are bold');
}

#--------
# tex selection logic: extension auto-detect and the explicit tex => 0/1 override
#--------
{	# a plain non-.tex name with no tex option => delimited, not LaTeX
	my ($csv, $tex) = paths();
	write_table([[qw(k v)], [1, 2]], $csv, 'row.names' => 0);
	ok(-e $csv, 'no tex + .csv name: file written');
	is(slurp($csv), "k,v\n1,2\n", 'no tex + .csv name: delimited output');
	lacks(slurp($csv), '\begin{tabular}', 'no tex + .csv name: output is not LaTeX');
}
{	# a .tex name turns LaTeX on with no explicit tex option
	my ($csv, $tex) = paths();
	write_table([[qw(k v)], [1, 2]], $tex, 'row.names' => 0);
	has(slurp($tex), '\begin{tabular}', '.tex name: LaTeX auto-selected');
}
{	# tex => 1 forces LaTeX into a name that does not end in .tex
	my ($csv, $tex) = paths();
	write_table([[qw(k v)], [1, 2]], $csv, 'tex' => 1, 'row.names' => 0);
	my $t = slurp($csv);
	has($t, '\begin{tabular}', 'tex => 1: LaTeX written to a .csv-named file');
	has($t, '%written by ',    'tex => 1: provenance comment present');
	lacks($t, 'k,v',           'tex => 1: delimited output suppressed');
}
{	# tex => 0 forces delimited even when the name ends in .tex
	my ($csv, $tex) = paths();
	write_table([[qw(k v)], [1, 2]], $tex, 'tex' => 0, 'row.names' => 0);
	is(slurp($tex), "k,v\n1,2\n", 'tex => 0: delimited output despite .tex name');
	lacks(slurp($tex), '\begin{tabular}', 'tex => 0: LaTeX suppressed for .tex name');
}

#--------
# tex.col.align
#--------
{
	my ($csv, $tex) = paths();
	write_table([[qw(k v)], ['x', 1]], $tex, 'tex.col.align' => 'l', 'row.names' => 0);
	has(slurp($tex), '\begin{tabular}{|l|l|} \hline', "tex.col.align => 'l'");
}
{
	my ($csv, $tex) = paths();
	write_table([[qw(k v)], ['x', 1]], $tex, 'tex.col.align' => 'r', 'row.names' => 0);
	has(slurp($tex), '\begin{tabular}{|r|r|} \hline', "tex.col.align => 'r'");
}

#--------
# tex.bold.1st.col
#--------
{
	my ($csv, $tex) = paths();
	# default (on): first data cell is wrapped in \textbf{}
	write_table([[qw(k v)], ['xx', 1]], $tex, 'row.names' => 0);
	has(slurp($tex), '\textbf{xx}', 'tex.bold.1st.col defaults on: first column bold');
}
{
	my ($csv, $tex) = paths();
	write_table([[qw(k v)], ['xx', 1]], $tex, 'tex.bold.1st.col' => 0, 'row.names' => 0);
	my $t = slurp($tex);
	lacks($t, '\textbf{xx}', 'tex.bold.1st.col => 0: first data cell not bold');
	has($t, '\textbf{k}', 'tex.bold.1st.col => 0: header still bold');
}

#--------
# tex.format (%.4g on numeric cells only)
#--------
{
	my ($csv, $tex) = paths();
	write_table([[qw(num txt)], [10.12345, 'a_b']], $tex,
		'tex.format' => 1, 'row.names' => 0);
	my $t = slurp($tex);
	has($t, '10.12', 'tex.format => 1: numeric cell rendered with %.4g');
	lacks($t, '10.12345', 'tex.format => 1: full-precision value replaced');
	has($t, 'a\_b', 'tex.format => 1: non-numeric cell still escaped, not formatted');
}
{
	my ($csv, $tex) = paths();
	write_table([[qw(num)], [10.12345]], $tex, 'row.names' => 0);
	has(slurp($tex), '10.12345', 'tex.format off (default): numeric cell left as-is');
}

#--------
# tex.size (directive emitted after \begin{tabular})
#--------
{
	my ($csv, $tex) = paths();
	write_table([[qw(k v)], ['x', 1]], $tex, 'tex.size' => '\small', 'row.names' => 0);
	my $t = slurp($tex);
	has($t, '\small', 'tex.size: directive present');
	ok(index($t, '\small') > index($t, '\begin{tabular}'),
		'tex.size: directive follows \begin{tabular}');
}
{
	my ($csv, $tex) = paths();
	write_table([[qw(k v)], ['x', 1]], $tex, 'row.names' => 0);
	lacks(slurp($tex), '\small', 'tex.size absent: no stray size directive');
}

#--------
# tex.comment (string and array ref), placed before \begin{tabular}
#--------
{
	my ($csv, $tex) = paths();
	write_table([[qw(k v)], ['x', 1]], $tex,
		'tex.comment' => 'single note', 'row.names' => 0);
	my $t = slurp($tex);
	has($t, "% single note", 'tex.comment scalar: emitted as a % line');
	ok(index($t, '% single note') < index($t, '\begin{tabular}'),
		'tex.comment scalar: appears before the tabular');
}
{
	my ($csv, $tex) = paths();
	write_table([[qw(k v)], ['x', 1]], $tex,
		'tex.comment' => ['line one', 'line two'], 'row.names' => 0);
	my $t = slurp($tex);
	has($t, "% line one", 'tex.comment arrayref: first line');
	has($t, "% line two", 'tex.comment arrayref: second line');
}
{
	my ($csv, $tex) = paths();
	write_table([[qw(k v)], ['x', 1]], $tex, 'row.names' => 0);
	# only the provenance comment line should be present
	my @comments = grep { /^%/ } split /\n/, slurp($tex);
	is(scalar(@comments), 1, 'tex.comment absent: only the provenance comment');
}

#--------
# cell escaping: # _ % &  and  > -> \textgreater{}
#--------
{
	my ($csv, $tex) = paths();
	write_table([[qw(v)], ['a_b'], ['x>y'], ['50%'], ['p#q'], ['r&s']], $tex,
		'row.names' => 0);
	my $t = slurp($tex);
	has($t, 'a\_b',              'escape: underscore');
	has($t, 'x\textgreater{}y',  'escape: > becomes \textgreater{}');
	has($t, '50\%',              'escape: percent');
	has($t, 'p\#q',              'escape: hash');
	has($t, 'r\&s',              'escape: ampersand');
}

#--------
# \includesvg{...svg} cells pass through unescaped
#--------
{
	my ($csv, $tex) = paths();
	write_table([[qw(fig)], ['\includesvg{a_b.svg}']], $tex, 'row.names' => 0);
	my $t = slurp($tex);
	has($t, '\includesvg{a_b.svg}', 'includesvg: passed through verbatim');
	lacks($t, 'a\_b.svg', 'includesvg: underscore inside is NOT escaped');
}

#--------
# LaTeX output works for every data-frame shape (column counts + files)
#--------
{
	my ($csv, $tex) = paths();
	write_table({ a => 1, b => 2, c => 3 }, $tex, 'row.names' => 1);
	# flat hash + row.names => 1 => empty label col + a,b,c = 4 columns
	has(slurp($tex), spec(4), 'flat hash: 4 columns (label + a,b,c)');
}
{
	my ($csv, $tex) = paths();
	write_table({ p => [1, 2], q => [3, 4] }, $tex, 'row.names' => 0);
	has(slurp($tex), spec(2), 'HoA: 2 columns');
	ok(-e $tex, 'HoA: LaTeX file created');
}
{
	my ($csv, $tex) = paths();
	write_table({ r1 => { x => 1, y => 2 }, r2 => { x => 3, y => 4 } }, $tex,
		'row.names' => 1);
	# HoH + row.names => 1 => outer-key label col + x,y = 3 columns
	has(slurp($tex), spec(3), 'HoH: 3 columns (label + x,y)');
}
{
	my ($csv, $tex) = paths();
	write_table([{ name => 'A', age => 1 }, { name => 'B', age => 2 }], $tex,
		'row.names' => 0);
	has(slurp($tex), spec(2), 'AoH: 2 columns');
}
{
	# row.names now defaults OFF: no leading label column unless asked for
	my ($csv, $tex) = paths();
	write_table({ a => 1, b => 2, c => 3 }, $tex);
	my $body = body_after_provenance(slurp($tex));
	has($body, spec(3), 'row.names default off: flat hash has no label column');
	lacks($body, '\textbf{} &', 'row.names default off: no empty leading header cell');
}

#--------
# AoA input: first inner array is the header unless col.names is given
#--------
{
	my ($csv, $tex) = paths();
	write_table([[qw(gene score)], ['TP53', 0.9], ['BRCA1', 0.7]], $tex,
		'row.names' => 0);
	has(slurp($tex), '\textbf{gene} & \textbf{score}', 'AoA: header from first inner array');
}
{
	my ($csv, $tex) = paths();
	# col.names => every inner array is data; row.names => 1 adds the index col
	write_table([['TP53', 0.9], ['BRCA1', 0.7]], $tex,
		'col.names' => [qw(gene score)], 'row.names' => 1);
	my $t = slurp($tex);
	has($t, spec(3), 'AoA + col.names: index col + gene,score = 3 columns');
	has($t, '\textbf{gene}', 'AoA: col.names header appears in LaTeX');
	has($t, 'TP53', 'AoA + col.names: first inner array is data, not header');
}

#--------
# error paths
#--------
{
	my ($csv, $tex) = paths();
	throws_ok {
		write_table([['h1', 'h2'], { a => 1 }], $tex, 'row.names' => 0)
	} qr/Array of Arrays/, 'AoA with a non-array element croaks';
}
{
	my ($csv, $tex) = paths();
	throws_ok {
		write_table([[qw(h)], [[1]]], $tex, 'row.names' => 0)
	} qr/nested reference/, 'AoA with a nested-reference cell croaks';
}
{
	# a ".tex" name in a missing subdir: tex is auto-on, so the LaTeX writer
	# is the one that fails to open the file.
	throws_ok {
		write_table([[qw(k v)], [1, 2]], "$dir/no_such_subdir/out.tex", 'row.names' => 0)
	} qr/Could not open/, 'unwritable .tex path croaks';
}
{
	# tex.tab.file has been removed: it is now just an unknown option.
	my ($csv, $tex) = paths();
	throws_ok {
		write_table([[qw(k v)], [1, 2]], $tex, 'tex.tab.file' => $tex, 'row.names' => 0)
	} qr/Unknown argument/, 'removed tex.tab.file option now croaks as unknown';
}

#--------
# leak safety: success and croak paths (mortal collector must be reclaimed).
# By now an earlier tex write has already loaded Cwd (used for the provenance
# line), so no module-load allocations are mistaken for leaks here.
#--------
no_leaks_ok {
	my ($csv, $tex) = paths();
	eval {
		write_table([[qw(gene score)], ['TP53', 0.912345], ['BRCA1', 0.7]], $tex,
			'tex.format' => 1, 'tex.size' => '\small',
			'tex.comment' => ['run 3', 'q < 0.05'], 'row.names' => 0)
	}
} 'write_table(tex): no memory leaks on success' unless $INC{'Devel/Cover.pm'};

no_leaks_ok {
	my ($csv, $tex) = paths();
	eval {
		write_table([[qw(k v)], [1, 2]], $csv, 'tex' => 0, 'row.names' => 0)
	}
} 'write_table(tex => 0): no leaks on the delimited path' unless $INC{'Devel/Cover.pm'};

no_leaks_ok {
	my ($csv, $tex) = paths();
	eval {
		write_table([{ x => 1, y => [1, 2] }], $tex)
	}
} 'write_table(tex): no leaks on AoH nested-ref croak' unless $INC{'Devel/Cover.pm'};

no_leaks_ok {
	my ($csv, $tex) = paths();
	eval {
		write_table([[qw(h)], [[1]]], $tex, 'row.names' => 0)
	}
} 'write_table(tex): no leaks on AoA nested-ref croak' unless $INC{'Devel/Cover.pm'};

no_leaks_ok {
	eval {
		write_table([[qw(k v)], [1, 2]], "$dir/no_such_subdir/out.tex", 'row.names' => 0)
	}
} 'write_table(tex): no leaks when the tex file cannot be opened' unless $INC{'Devel/Cover.pm'};

done_testing();
