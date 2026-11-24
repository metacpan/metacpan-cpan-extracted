#!/usr/bin/env perl
require 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;
use File::Temp 'tempdir';
use Stats::LikeR qw(read_table write_table);

# How read_table and write_table treat damaged input and failing writes.
# Hand-written: these are this module's own file-handling contracts, and there
# is no R or Python test to take them from.  What pandas does is the reference
# for the behavior: pd.read_excel() of a file that is not a zip archive, or of
# one cut short, raises (zipfile.BadZipFile) rather than returning an empty
# frame; Python's zipfile checks each member's CRC-32 (ZipExtFile._update_crc,
# zipfile 3.14.2); openpyxl hands back only worksheets, not chart sheets
# (openpyxl 3.1, Workbook.worksheets against chartsheets); and a failed
# DataFrame.to_csv(path) is no atomic write, which is the one place this module
# is stricter than pandas, on purpose.
#
# Fixtures are built in the test with core IO::Compress::Zip and by patching
# bytes, so that nothing needs python3 or R and no binary is committed.

no warnings 'once';
my $have_zip = eval { require IO::Compress::Zip; 1 };
plan skip_all => 'IO::Compress::Zip (core) not available' unless $have_zip;

my $dir = tempdir(CLEANUP => 1);
my $seq = 0;
sub path { "$dir/f" . $seq++ . '.' . ($_[0] // 'xlsx') }

sub slurp {
	open my $fh, '<:raw', $_[0] or die "cannot read $_[0]: $!";
	local $/;
	return scalar <$fh>;
}
sub spew {
	my ($f, $bytes) = @_;
	open my $fh, '>:raw', $f or die "cannot write $f: $!";
	print {$fh} $bytes or die "cannot write $f: $!";
	close $fh or die "cannot write $f: $!";
	return $f;
}
sub dies { my ($c) = @_; eval { $c->(); 1 } ? undef : $@ }

my $ns  = 'http://schemas.openxmlformats.org/spreadsheetml/2006/main';
my $rns = 'http://schemas.openxmlformats.org/package/2006/relationships';
my $ons = 'http://schemas.openxmlformats.org/officeDocument/2006/relationships';

# One workbook from [ name, type, member ] sheets, each worksheet holding the
# same two-column table.  $opt{store} stores the members instead of deflating.
sub workbook {
	my ($sheets, %opt) = @_;
	my (@sheet_tags, @rels, @parts);
	my $i = 0;
	for my $s (@$sheets) {
		my ($name, $type, $member) = @$s;
		$i++;
		push @sheet_tags, qq{<sheet name="$name" sheetId="$i" r:id="rId$i"/>};
		push @rels, qq{<Relationship Id="rId$i" Type="$ons/$type" Target="$member"/>};
		my $body = $type eq 'worksheet'
			? qq{<worksheet xmlns="$ns"><sheetData>}
			  . '<row r="1"><c r="A1" t="inlineStr"><is><t>k</t></is></c><c r="B1" t="inlineStr"><is><t>v</t></is></c></row>'
			  . qq{<row r="2"><c r="A2"><v>$i</v></c><c r="B2"><v>$i$i</v></c></row>}
			  . '</sheetData></worksheet>'
			: qq{<chartsheet xmlns="$ns"><sheetViews/></chartsheet>};
		push @parts, [ "xl/$member", $body ];
	}
	my @m = (
		[ '[Content_Types].xml', '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"/>' ],
		[ 'xl/workbook.xml', qq{<workbook xmlns="$ns" xmlns:r="$ons"><sheets>}
			. join('', @sheet_tags) . '</sheets></workbook>' ],
		[ 'xl/_rels/workbook.xml.rels', qq{<Relationships xmlns="$rns">}
			. join('', @rels) . '</Relationships>' ],
		@parts,
	);
	my $path = path();
	my @first = @{ shift @m };
	my @method = $opt{store} ? (Method => IO::Compress::Zip::ZIP_CM_STORE()) : ();
	my $z = IO::Compress::Zip->new($path, Name => $first[0], @method)
		or die "cannot start $path";
	print {$z} $first[1];
	for my $p (@m) {
		$z->newStream(Name => $p->[0], @method) or die "cannot add $p->[0]";
		print {$z} $p->[1];
	}
	$z->close or die "cannot close $path";
	return $path;
}

# ---- 1. a file that is not a readable workbook dies, naming the file --------
{
	my $good = workbook([ [ 'Data', 'worksheet', 'worksheets/sheet1.xml' ] ]);
	is_deeply( read_table($good), [ { k => '1', v => '11' } ], 'the fixture reads' );
	my $bytes = slurp($good);

	my $junk = spew(path(), "this is text, not a workbook\n" x 20);
	like( dies(sub { read_table($junk) }),
		qr/\Aread_table: '\Q$junk\E' is not a readable \.xlsx workbook: /,
		'a text file named .xlsx dies (it used to read as an empty table)' );

	my $short = spew(path(), 'PK');
	like( dies(sub { read_table($short) }), qr/\Q$short\E' is not a readable/,
		'a two-byte file dies' );

	my $cut = spew(path(), substr($bytes, 0, length($bytes) - 30));
	like( dies(sub { read_table($cut) }),
		qr/\Aread_table: '\Q$cut\E' is not a readable \.xlsx workbook: .*truncated/,
		'an archive missing its end record dies (it used to read as no rows)' );

	# The 2000-row table from the audit: 8 bytes flipped inside the deflate data
	# used to return a partial table.
	my $rows = path();
	write_table([ map { { id => $_, s => "row $_" } } 1 .. 2000 ], $rows, quiet => 1);
	{
		my $b = slurp($rows);
		my $at = index($b, '<row r="1000"');
		ok( $at > 0, 'write_table stores its worksheet, so the data is findable' );
		substr($b, $at + 4, 1) = 'X';	# same length: only the CRC can tell
		my $bad = spew(path(), $b);
		like( dies(sub { read_table($bad) }), qr/fails its CRC-32 check/,
			'a stored member changed without changing its size fails its CRC' );
	}
	{
		# a deflated member with bytes of its compressed data overwritten
		my $text = join '', map { "<row>$_</row>" } 1 .. 4000;
		my $f = path('zip');
		IO::Compress::Zip::zip(\$text, $f, Name => 'xl/worksheets/sheet1.xml')
			or die "cannot write $f";
		my $b = slurp($f);
		substr($b, 60, 8) = "\xff\x00\xa5\x5a\x12\x34\x56\x78";
		my $bad = spew(path(), $b);
		my $msg = dies(sub { Stats::LikeR::_unzip_member($bad, 'xl/worksheets/sheet1.xml') });
		like( $msg, qr/\Aread_table: '\Q$bad\E' is not a readable \.xlsx workbook: member 'xl\/worksheets\/sheet1\.xml' /,
			'a deflate stream with damaged bytes dies' );
	}
}

# ---- 4. a size the directory misstates is corruption, reported once ---------
{
	my $f = workbook([ [ 'Data', 'worksheet', 'worksheets/sheet1.xml' ] ], store => 1);
	my $b = slurp($f);
	# patch the uncompressed size of the worksheet's central directory entry
	my ($pos, $at) = (-1, -1);
	while (($pos = index($b, "PK\1\2", $pos + 1)) >= 0) {
		my $nl = unpack('v', substr($b, $pos + 28, 2));
		if (substr($b, $pos + 46, $nl) eq 'xl/worksheets/sheet1.xml') { $at = $pos; last }
	}
	ok( $at >= 0, 'found the central directory entry' );
	my $usz = unpack('V', substr($b, $at + 24, 4));
	substr($b, $at + 24, 4) = pack('V', $usz + 100);
	my $bad = spew(path(), $b);
	like( dies(sub { read_table($bad) }),
		qr/member 'xl\/worksheets\/sheet1\.xml' is \d+ bytes, not the \d+ its directory entry gives/,
		'a wrong size in the directory dies' );
}

# ---- 5. chart sheets are not tables ----------------------------------------
{
	my $f = workbook([ [ 'Data', 'worksheet', 'worksheets/sheet1.xml' ],
	                   [ 'Chart1', 'chartsheet', 'chartsheets/sheet1.xml' ] ]);
	is_deeply( read_table($f), [ { k => '1', v => '11' } ],
		'a workbook of one worksheet and one chart sheet is that one table, not a hash' );
	my $g = workbook([ [ 'Chart1', 'chartsheet', 'chartsheets/sheet1.xml' ],
	                   [ 'A', 'worksheet', 'worksheets/sheet1.xml' ],
	                   [ 'B', 'worksheet', 'worksheets/sheet2.xml' ] ]);
	is_deeply( [ sort keys %{ read_table($g) } ], [ 'A', 'B' ],
		'a chart sheet is not a key of the workbook hash' );
	is_deeply( read_table($g, sheet => 'B'), [ { k => '3', v => '33' } ],
		'and the worksheets after it are still read by their own names' );
	my $h = workbook([ [ 'Chart1', 'chartsheet', 'chartsheets/sheet1.xml' ] ]);
	like( dies(sub { read_table($h) }), qr/has no worksheet/, 'a workbook of only charts dies' );
}

# ---- 6. duplicate sheet names ----------------------------------------------
{
	my $f = workbook([ [ 'Same', 'worksheet', 'worksheets/sheet1.xml' ],
	                   [ 'Same', 'worksheet', 'worksheets/sheet2.xml' ] ]);
	like( dies(sub { read_table($f) }),
		qr/\Aread_table: worksheet name 'Same' is used by more than one sheet of \Q$f\E\n/,
		'two sheets of one name die rather than the later replacing the earlier' );
}

# ---- 7. many sheets: correctness (the speed is measured in the notes) -------
{
	my %book = map { ("s$_" => [ { n => $_ } ]) } 1 .. 400;
	my $f = path();
	write_table(\%book, $f, quiet => 1);
	my $back = read_table($f);
	is( scalar keys %$back, 400, 'a 400-sheet workbook reads back whole' );
	is( $back->{s400}[0]{n}, '400', 'to its last sheet' );
}

# ---- 2. a write that croaks leaves an existing file as it was ---------------
sub tmp_left { return scalar grep { /\.tmp\z/ } glob("$dir/*") }
{
	package DieAt;
	require Tie::Array;
	our @ISA = ('Tie::StdArray');
	sub FETCH { die "boom\n" if $_[1] == 2; $_[0]->[$_[1]] }
}
my %bad = (
	'a cell over 32767 characters' => sub { [ { a => 'x' x 40000 } ] },
	'a code point above U+10FFFF'  => sub { [ { a => "ok", b => chr(0x110000) } ] },
	'a tied FETCH that dies'       => sub { tie my @t, 'DieAt'; @t = (1 .. 5); return { a => \@t } },
);
for my $what (sort keys %bad) {
	for my $ext (qw(xlsx csv tex)) {
		next if $ext ne 'xlsx' && $what =~ /32767|U\+10FFFF/;	# Excel's limits only
		my $f = path($ext);
		spew($f, "KEEP\n");
		ok( !eval { write_table($bad{$what}->(), $f, quiet => 1); 1 }, "$ext, $what: croaks" );
		is( slurp($f), "KEEP\n", "$ext, $what: the existing file is untouched" );
		is( tmp_left(), 0, "$ext, $what: and no temporary file is left" );
		my $new = path($ext);
		ok( !eval { write_table($bad{$what}->(), $new, quiet => 1); 1 }, "$ext, $what: croaks again" );
		ok( !-e $new, "$ext, $what: and creates no file where there was none" );
	}
}

# the column count is checked from the shape, before the file is opened
{
	my $f = path();
	spew($f, "KEEP\n");
	my %wide = map { ("c$_" => [1]) } 1 .. 16385;
	my $msg = dies(sub { write_table(\%wide, $f, quiet => 1) });
	like( $msg, qr/would have 16385 columns, more than the 16384 an Excel worksheet holds/,
		'a 16385-column hash of arrays is refused' );
	is( slurp($f), "KEEP\n", 'the existing file is untouched' );
	$msg = dies(sub { write_table([[1, 2]], $f, quiet => 1, col_names => [ map { "c$_" } 1 .. 16385 ]) });
	like( $msg, qr/16385 columns/, 'col_names past the limit is refused' );
	is( slurp($f), "KEEP\n", 'the existing file is untouched again' );
}

# success replaces the file, and keeps its permission bits
SKIP: {
	skip 'permission bits are not POSIX here', 2 if $^O eq 'MSWin32';
	my $f = path('csv');
	spew($f, "old\n");
	chmod 0640, $f or die;
	write_table([ { a => 1 } ], $f, quiet => 1);
	is( slurp($f), "a\n1\n", 'a successful write replaces the file' );
	is( sprintf('%04o', (stat $f)[2] & 07777), '0640', 'and keeps its permissions' );
}

# a target that a handle still holds open is replaced too.  Windows refuses to
# rename over such a file, so there the table is copied into it in place
# (wt_target_copy()); 0.3428 croaked "could not replace ...: Permission denied"
# instead, and failed t/numeric.options.t, t/write_table.t and
# t/write_table.tex.rownames.t on every Windows perl, which name a File::Temp
# file they still hold.  On POSIX the rename succeeds and only the outcome is
# checked here; to run the copy on Linux, LD_PRELOAD a rename() that fails with
# EACCES while the process has the target open, as Windows does.
for my $ext (qw(xlsx csv tex)) {
	my $fresh = path($ext);
	write_table([ { a => 1, b => 'x' } ], $fresh, quiet => 1);
	my $held = path($ext);
	spew($held, 'z' x 100_000);	# longer than any of the tables: the copy must truncate it
	open my $h, '<:raw', $held or die "cannot read $held: $!";
	ok( eval { write_table([ { a => 1, b => 'x' } ], $held, quiet => 1); 1 },
		"$ext: a target held open is written" ) or diag $@;
	close $h;
	ok( slurp($held) eq slurp($fresh), "$ext: with the bytes a fresh file gets" );
	is( tmp_left(), 0, "$ext: and no temporary file is left" );
}

# targets that are not regular files are written in place
SKIP: {
	skip 'no /dev/null here', 2 unless -c '/dev/null';
	ok( eval { write_table([ { a => 1 } ], '/dev/null', quiet => 1); 1 }, '/dev/null is written' )
		or diag $@;
	ok( -c '/dev/null', 'and is still a character device' );
}
SKIP: {
	skip 'symlinks are not portable here', 3
		if $^O eq 'MSWin32' || !eval { symlink('', ''); 1 };
	my $real = path('csv');
	spew($real, "old\n");
	my $link = path('csv');
	skip 'cannot make a symlink', 3 unless symlink($real, $link);
	write_table([ { a => 1 } ], $link, quiet => 1);
	ok( -l $link, 'a symlink is still a symlink after a write through it' );
	is( slurp($real), "a\n1\n", 'and its target holds the table' );
	is( tmp_left(), 0, 'with no temporary file left' );
}

# ---- 3. LaTeX: valid UTF-8 as it is, else Latin-1 read and encoded ----------
{
	my $f = path('tex');
	my $latin = "caf\xe9";	# bytes: Latin-1
	my $flagged = "caf\x{e9}"; utf8::upgrade($flagged);	# the same text, flagged
	write_table({ $latin => [ $latin, $flagged ] }, $f, quiet => 1,
		row_names => 1, undef_val => "und\xe9");
	my $t = slurp($f);
	is( () = $t =~ /\xc3\xa9/g, 3, 'the header, and both cells, are C3 A9' ) or diag $t;
	unlike( $t, qr/(?<![\xc3])\xe9/, 'no bare E9 byte is written' );

	my $g = path('tex');
	write_table([ { a => undef } ], $g, quiet => 1, undef_val => "n\xe9");
	like( slurp($g), qr/n\xc3\xa9/, 'undef_val is encoded the same way' );

	my $h = path('tex');
	write_table([ { a => "caf\xc3\xa9" } ], $h, quiet => 1);
	like( slurp($h), qr/caf\xc3\xa9\}/, 'bytes that already are valid UTF-8 are written as they are' );
}

done_testing();
