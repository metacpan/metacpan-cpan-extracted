#!/usr/bin/env perl

# read_table(skiprows => ...): what pandas' tests (t/read_table.skiprows.pandas.t)
# do not reach -- the argument's validation, how many times and in what order a
# sub is asked, the parser paths a skipped row takes (a regex sep, qr/\s+/,
# bare-CR lines, a byte-order mark, lines that are not UTF-8, quote => '', a
# commented-out header after the skipped rows, compressed input), each output
# type, an .xlsx's blank rows, and leaks.
#
# The rule is pandas' (pandas 3.0.4, read_csv() and read_excel()): 0-based
# indices; a delimited file's rows are records, a blank or comment line is one,
# and a quoted field across lines is one row with the line it starts on; a
# sheet's rows are its row numbers less one, blank rows included.

require 5.010;
use strict;
use warnings FATAL => 'all';
use File::Temp 'tempdir';
use Test::More;
use Stats::LikeR 'read_table';

no warnings 'once';	# $IO::Compress::*::*Error are read, never assigned
my $have_zip = eval { require IO::Compress::Zip; 1 };
my $have_gz  = eval { require IO::Compress::Gzip; 1 };
my $HAVE_LEAKTRACE;
BEGIN {
	$HAVE_LEAKTRACE = eval { require Test::LeakTrace; Test::LeakTrace->import('no_leaks_ok'); 1 } ? 1 : 0;
}
my $dir = tempdir(CLEANUP => 1);
my $n = 0;
sub csv {
	my ($text, $ext) = @_;
	my $path = "$dir/c" . $n++ . ($ext // '.csv');
	open my $fh, '>:raw', $path or die "cannot write $path: $!";
	print {$fh} $text;
	close $fh or die "cannot write $path: $!";
	return $path;
}
sub aoa { read_table(shift, output_type => 'aoa', @_) }
sub dies_like {
	my ($code, $re, $name) = @_;
	my $ok = !eval { $code->(); 1 };
	ok($ok && $@ =~ $re, $name) or diag $ok ? "died: $@" : 'lived';
}

my $f = csv("a,b\n1,x\n2,y\n3,z\n");

# validation
for my $bad (-1, '1.5', 'x', '', " 1", "1\n", [1, 'a'], [undef], [-2], [[1]], {}, \1) {
	my $show = ref $bad ? ref($bad) . (ref $bad eq 'ARRAY' ? ' [' . join(',', map { $_ // 'undef' } @$bad) . ']' : '')
		: "'$bad'";
	$show =~ s/\n/\\n/g;
	dies_like(sub { read_table($f, skiprows => $bad) },
		qr/read_table: error: 'skiprows' must be a non-negative integer, an ARRAY reference of them, or a CODE reference/,
		"skiprows => $show is refused");
}
is_deeply(aoa($f, skiprows => undef), aoa($f), 'skiprows => undef is no skiprows');
is_deeply(aoa($f, skiprows => 0), aoa($f), 'skiprows => 0 skips nothing');
is_deeply(aoa($f, skiprows => []), aoa($f), 'skiprows => [] skips nothing');
is_deeply(aoa($f, skiprows => '007'), [], "skiprows => '007' is 7, every row");
is_deeply(aoa($f, skiprows => '99999999999999999999'), [], 'a count past ~0 skips every row');
is_deeply(aoa($f, skiprows => ['99999999999999999999', 1]), [[qw(a b)], [2, 'y'], [3, 'z']],
	'an index past ~0 is no row, and the rest still count');
is_deeply(aoa($f, skiprows => [1, 1.0, '01']), [[qw(a b)], [2, 'y'], [3, 'z']], 'one index, three spellings');
{
	package Blessed::Skip;
	sub new { my $c = shift; bless sub { $_[0] == 1 }, $c }
}
is_deeply(aoa($f, skiprows => Blessed::Skip->new), [[qw(a b)], [2, 'y'], [3, 'z']], 'a blessed CODE reference');

# the sub: its argument, and asked once per row, in order -- including the
# rows the commented-out-header look reads before the parse
{
	my @asked;
	my $g = csv("junk\n# id,val\n\n1,2\n3,4\n");
	is_deeply(aoa($g, skiprows => sub { push @asked, $_[0]; $_[0] == 0 }), [[qw(id val)], [1, 2], [3, 4]],
		'a commented-out header after a skipped row is the header');
	is_deeply(\@asked, [0 .. 4], '... and the sub is asked once per row, in order');
	@asked = ();
	aoa(csv(qq{h\n"a\nb"\nc\n}), skiprows => sub { push @asked, $_[0]; 0 });
	is_deeply(\@asked, [0, 1, 2], 'a quoted field across lines is asked about once');
	@asked = ();
	aoa($f, skiprows => sub { push @asked, [@_]; 0 });
	is_deeply(\@asked, [[0], [1], [2], [3]], 'the sub is passed the index and nothing else');
}

# the parser's paths
is_deeply(aoa(csv(qq{a|b\n"skip|\nstill"|x\n1|2\n}), sep => qr/\|/, skiprows => [1]), [[qw(a b)], [1, 2]],
	'a regex sep: a skipped row\'s quoted field across lines is followed');
is_deeply(aoa(csv(qq{a::b\nq::"x::\ny"\n1::2\n}), sep => '::', skiprows => [1]), [[qw(a b)], [1, 2]],
	'a two-byte sep: a quote at the start of a later field is followed');
is_deeply(aoa(csv(qq{a b\n  "x\n y" z\n1 2\n}), sep => qr/\s+/, skiprows => [1]), [[qw(a b)], [1, 2]],
	'qr/\s+/: leading blanks before a skipped row\'s quote');
is_deeply(aoa(csv(qq{a,b\nx,y""z\n1,2\n}), skiprows => [1]), [[qw(a b)], [1, 2]],
	'a skipped row with a \'"\' inside a field opens nothing');
is_deeply(aoa(csv(qq{a,b\n"x""\ny",2\n1,2\n}), skiprows => [1]), [[qw(a b)], [1, 2]],
	'a doubled quote inside a skipped quoted field is text');
is_deeply(aoa(csv(qq{a,b\n"x\n1,2\n}), skiprows => [1], quote => ''), [[qw(a b)], [1, 2]],
	'quote => \'\': a skipped row\'s \'"\' quotes nothing');
is_deeply(aoa(csv("t\rskip\ra,b\r1,2\r"), skiprows => 2), [[qw(a b)], [1, 2]], 'lines that end in a bare CR');
is_deeply(aoa(csv("\xEF\xBB\xBFtitle\na,b\n1,2\n"), skiprows => 1), [[qw(a b)], [1, 2]],
	'a skipped first line takes its byte-order mark with it');
is_deeply(aoa(csv("\xEF\xBB\xBFa,b\n1,2\n"), skiprows => [2]), [[qw(a b)], [1, 2]],
	'... and a kept one still loses it');
{
	my $re = qr/\x{2014}/;
	is_deeply(aoa(csv("\xe9 not UTF-8\na\xe2\x80\x94b\n1\xe2\x80\x942\n"), sep => $re, skiprows => 1),
		[[qw(a b)], [1, 2]], 'a skipped line that is not UTF-8 is no error under a UTF-8 sep regex');
}
is_deeply(aoa(csv("a,b\n#c\n1,2\n"), skiprows => [1]), [[qw(a b)], [1, 2]], 'a comment line is a row');
is_deeply(aoa(csv("x\nV1,V2\n1,2\n"), skiprows => 1, header => 0), [[qw(V1 V2)], [qw(V1 V2)], [1, 2]],
	'header => 0: the first row kept is data');
is_deeply(read_table(csv("t\nh,a\nr1,1\nr2,2\n"), skiprows => 1, output_type => 'hoh'),
	{ r1 => { a => 1 }, r2 => { a => 2 } }, 'hoh');
is_deeply(read_table(csv("note\na,b\nr1,1,2\n"), skiprows => 1, auto_row_names => 1),
	[{ row_name => 'r1', a => 1, b => 2 }], 'auto_row_names, after a skipped row');
is_deeply(aoa(csv("title\n\n# hdr\na,b\n1,2\n"), skiprows => [0]), [[qw(a b)], [1, 2]],
	'a blank line and a "# " comment after the skipped rows are still dropped');
SKIP: {
	skip 'IO::Compress::Gzip (core) is not installed', 2 unless $have_gz;
	my $gz = "$dir/t.tsv.gz";
	IO::Compress::Gzip::gzip(\"skip\n# a\tb\n1\t2\n" => $gz) or die 'gzip failed';
	my @asked;
	is_deeply(aoa($gz, skiprows => sub { push @asked, $_[0]; $_[0] == 0 }), [[qw(a b)], [1, 2]],
		'gzip: a commented-out header after a skipped row');
	is_deeply(\@asked, [0, 1, 2], '... the sub asked once per row');
}

# an .xlsx: blank rows are rows, a skipped row does not widen the sheet
SKIP: {
	skip 'IO::Compress::Zip (core) is not installed', 6 unless $have_zip;
	my $ns = 'http://schemas.openxmlformats.org/spreadsheetml/2006/main';
	my $path = "$dir/s.xlsx";
	my $str = sub { qq{<c r="$_[0]" t="inlineStr"><is><t>$_[1]</t></is></c>} };
	my $num = sub { qq{<c r="$_[0]"><v>$_[1]</v></c>} };
	my $sheet = qq{<row r="1">} . $str->('A1', 'a title') . $str->('E1', 'wide') . '</row>'
		. qq{<row r="3">} . $str->('A3', 'a') . $str->('B3', 'b') . '</row>'
		. qq{<row r="4">} . $num->('A4', 1) . $num->('B4', 2) . '</row>'
		. qq{<row r="6">} . $num->('A6', 3) . $num->('B6', 4) . '</row>';
	my @part = (
		'xl/workbook.xml' => qq{<workbook xmlns="$ns" xmlns:r="r"><sheets><sheet name="S" sheetId="1" r:id="rId1"/></sheets></workbook>},
		'xl/_rels/workbook.xml.rels' => '<Relationships><Relationship Id="rId1" Type="x/worksheet" Target="worksheets/sheet1.xml"/></Relationships>',
		'xl/worksheets/sheet1.xml' => qq{<worksheet xmlns="$ns"><sheetData>$sheet</sheetData></worksheet>},
	);
	my $z = IO::Compress::Zip->new($path, Name => $part[0]) or die $IO::Compress::Zip::ZipError;
	$z->print($part[1]);
	for (my $i = 2; $i < @part; $i += 2) { $z->newStream(Name => $part[$i]); $z->print($part[$i + 1]) }
	$z->close;
	is_deeply(aoa($path, skiprows => 1), [[qw(a b)], [1, 2], [undef, undef], [3, 4]],
		'the skipped title row is not the header, and does not widen the sheet to E');
	is_deeply(aoa($path, skiprows => [0, 4]), [[qw(a b)], [1, 2], [3, 4]], 'a skipped blank row is not emitted');
	is_deeply(aoa($path, skiprows => [0, 3]), [[qw(a b)], [undef, undef], [3, 4]],
		'a skipped row with values, between kept ones');
	is_deeply(read_table($path, skiprows => 1, output_type => 'hoh'), { 1 => { b => 2 }, 3 => { b => 4 } },
		'hoh leaves blank rows out, as without skiprows');
	my @asked;
	aoa($path, skiprows => sub { push @asked, $_[0]; $_[0] == 0 });
	is_deeply(\@asked, [0 .. 5], 'a sheet\'s two passes ask the sub once per row, in order, to the last row with a value');
	is_deeply(read_table($path, skiprows => 1, sheet => 'S', keep_cols => 'b', output_type => 'aoa'),
		[['b'], [2], [undef], [4]], 'keep_cols with skiprows');
}

SKIP: {
	skip 'Test::LeakTrace not installed', 5 unless $HAVE_LEAKTRACE;
	skip 'running under Devel::Cover', 5 if $INC{'Devel/Cover.pm'};
	my $q = csv(qq{junk\n"a\nb",c\n# h,v\n1,2\n});
	my $re = qr/,/;	# compiled outside the blocks: 5.10.0's pp_qr() leaks an SV per qr//
	no_leaks_ok { read_table($q, skiprows => [0, 1]) } 'no leaks: a list, with the header look';
	no_leaks_ok { read_table($q, skiprows => sub { $_[0] < 2 }) } 'no leaks: a sub, with the header look';
	no_leaks_ok { read_table($q, skiprows => 2, sep => $re) } 'no leaks: a count and a regex sep';
	no_leaks_ok { eval { read_table($q, skiprows => sub { die "no\n" }) } } 'no leaks: a sub that dies';
	no_leaks_ok { read_table($q, skiprows => [0, 1], output_type => 'hoh') } 'no leaks: hoh';
}

done_testing;
