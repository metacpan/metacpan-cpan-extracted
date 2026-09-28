#!/usr/bin/env perl
require 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;
use File::Temp 'tempdir';
use Stats::LikeR ();

# Stats::LikeR::_unzip_member() and the _unzip_member_fast() path under it.
#
# _unzip_member_fast() reads the archive's central directory itself and inflates
# one member with Compress::Raw::Zlib, which is what makes reading an .xlsx
# worth doing since 0.316 put the worksheet parser in XS: decompression became
# the whole cost, and IO::Uncompress::Unzip spends 0.174 s where inflating the
# same 36 MB worksheet part directly takes 0.052 s.  It declines anything it
# does not recognise and _unzip_member falls back to IO::Uncompress::Unzip, so
# the two contracts here are that it returns the bytes that went in, and that
# what it declines still comes back exactly as it did before it existed.
#
# Hand-written, with no R or Python counterpart to take cases from: this is the
# ZIP container ECMA-376 puts an .xlsx in, not a statistical function.  The
# shapes come from PKWARE's APPNOTE.TXT 6.3.10 -- section 4.3.16 (end of
# central directory), 4.3.12 (a central directory entry), 4.3.7 (a local file
# header) -- and the ones chosen are those a writer can actually produce:
# deflated and stored members, streamed members (which move the sizes into a
# trailing data descriptor) and non-streamed ones, an archive comment, zip64,
# and an archive that is really two archives end to end.
#
# Every accepted member is asserted against the content that went into the
# fixture, NOT against what IO::Uncompress::Unzip makes of it, because on the
# older perls in the matrix it cannot always make anything of it: 2.020 (perl
# 5.10.1) and 2.024 (5.12.5) refuse `Streamed Stored content' outright, and
# fail to find any member past the first in a streamed multi-member archive --
# both of which this path reads.  Where the fallback does return a member it is
# cross-checked, which is what the "and IO::Uncompress::Unzip agrees" assertions
# are; on a perl whose IO-Compress cannot read the fixture they pass by saying
# nothing, and the assertion against the known bytes is what carries the case.
#
# Fixtures are built with core IO::Compress::Zip, as t/read_table.xlsx.t and
# t/read_table.xlsx.parser.t build theirs -- but through newStream() rather than
# `Append => 1'.  The difference matters and has a case of its own below.

no warnings 'once';	# $IO::Compress::Zip::ZipError is read, never assigned
my $have_zip = eval { require IO::Compress::Zip; 1 };
plan skip_all => 'IO::Compress::Zip (core) not available' unless $have_zip;
require IO::Uncompress::Unzip;

my $dir = tempdir(CLEANUP => 1);
my $seq = 0;

# One archive from a list of [ name, content, %member_options ]. newStream()
# keeps it a single archive with one central directory covering every member,
# which is what a real writer produces.
sub mkzip {
	my ($members, %archive_opts) = @_;
	# read_table decides a file is a workbook by its name, so a fixture meant
	# to be read as one needs the extension; everything else stays a .zip.
	my $ext  = delete $archive_opts{_ext};
	my $path = "$dir/z" . $seq++ . '.' . (defined $ext ? $ext : 'zip');
	my @m    = @$members;
	my ($name, $content, %opt) = @{ shift @m };
	my $z = IO::Compress::Zip->new($path, Name => $name, %archive_opts, %opt)
		or die "cannot start $path: $IO::Compress::Zip::ZipError";
	print {$z} $content or die "cannot write $name: $!";
	for my $next (@m) {
		my ($n2, $c2, %o2) = @$next;
		$z->newStream(Name => $n2, %o2)
			or die "cannot add $n2: $IO::Compress::Zip::ZipError";
		print {$z} $c2 or die "cannot write $n2: $!";
	}
	$z->close or die "cannot close $path: $!";
	return $path;
}

# What the fallback makes of a member, read the way _unzip_member reads it.
sub slow {
	my ($file, $member) = @_;
	my $z = IO::Uncompress::Unzip->new($file, Name => $member) or return undef;
	my $content = '';
	my ($off, $n) = (0, 0);
	while (($n = $z->read($content, 1 << 20, $off)) > 0) { $off += $n }
	$z->close;
	return $content;
}

# An accepted member: the fast path reads it, _unzip_member returns it, and the
# bytes are the ones that went in. Compared with eq rather than is(), because a
# mismatch on a 5 KB member would otherwise print both copies of it.
sub reads_back {
	my ($file, $member, $want, $label) = @_;
	my ($handled, $ref) = Stats::LikeR::_unzip_member_fast($file, $member);
	is( $handled, 1, "$label: read by the fast path" );
	ok( defined $ref && $$ref eq $want, "$label: byte for byte" )
		or diag sprintf('got %s bytes, want %d',
			defined $ref ? length $$ref : 'undef', length $want);
	my $got = Stats::LikeR::_unzip_member($file, $member);
	ok( defined $got && $$got eq $want, "$label: and through _unzip_member" );
	my $slow = slow($file, $member);
	ok( !defined $slow || $slow eq $want,
		"$label: and IO::Uncompress::Unzip agrees where it can read it" );
}

# A declined archive: _unzip_member has to answer exactly what it answered
# before the fast path existed, which is whatever the fallback says -- including
# saying nothing.
sub unchanged {
	my ($file, $member, $label) = @_;
	is( (Stats::LikeR::_unzip_member_fast($file, $member))[0], 0,
		"$label: declined" );
	my $got  = Stats::LikeR::_unzip_member($file, $member);
	my $slow = slow($file, $member);
	is( defined $got, defined $slow,
		"$label: and _unzip_member answers as the fallback does" );
	ok( !defined $got || $$got eq $slow, "$label: with the same bytes" );
}

# Content that is worth compressing and content that is not: a stored member
# and a deflated one take different branches, and the bytes have to survive
# either way.
my $text  = join('', map { "row $_,value $_\n" } 1 .. 2000);
my $noise = pack('C*', map { ($_ * 37 + 11) % 256 } 1 .. 5000);

{
	my $f = mkzip([ ['a/one.xml', $text], ['a/two.xml', $noise] ]);
	reads_back($f, 'a/one.xml', $text,  'deflated text');
	reads_back($f, 'a/two.xml', $noise, 'deflated binary');
}

{
	my $f = mkzip([ ['stored.xml', $text,
	                 Method => IO::Compress::Zip::ZIP_CM_STORE()],
	                ['after.xml', $noise] ]);
	reads_back($f, 'stored.xml', $text,  'stored member');
	reads_back($f, 'after.xml',  $noise, 'the member after a stored one');
}

# An empty member: length 0, still a member, and not the same answer as absent.
{
	my $f = mkzip([ ['empty.xml', ''], ['after.xml', $text] ]);
	reads_back($f, 'empty.xml', '',    'empty member');
	reads_back($f, 'after.xml', $text, 'the member after an empty one');
	my ($handled, $ref) = Stats::LikeR::_unzip_member_fast($f, 'empty.xml');
	is( $$ref, '', 'an empty member is an empty string, not undef' );
}

# newStream() sets general-purpose bit 3 on every member, which moves the sizes
# out of the local header into a descriptor after the data; the one-shot zip()
# below can seek back and so writes them in the header. The central directory
# carries them either way, and that is what _unzip_member_fast reads.
{
	my $p = "$dir/oneshot.zip";
	IO::Compress::Zip::zip(\$text, $p, Name => 'plain.xml')
		or die "cannot write $p: $IO::Compress::Zip::ZipError";
	reads_back($p, 'plain.xml', $text, 'a member with its sizes in the header');
}

# A name another name begins with, and one another name ends with: the walk
# compares whole names, so neither may be mistaken for the other.
{
	my $f = mkzip([ ['xl/sheet.xml',  $text],
	                ['xl/sheet.xml2', $noise],
	                ['sheet.xml',     'third'] ]);
	reads_back($f, 'xl/sheet.xml',  $text,   'a name another name begins with');
	reads_back($f, 'xl/sheet.xml2', $noise,  'the longer name');
	reads_back($f, 'sheet.xml',     'third', 'a name another name ends with');
}

# An archive comment pushes the end-of-central-directory record away from the
# end of the file, and a comment holding that record's own signature gives the
# backwards scan a decoy: only the candidate whose record ends exactly where the
# file does is the real one.
{
	my $f = mkzip([ ['c.xml', $text] ], ZipComment => 'a plain comment');
	reads_back($f, 'c.xml', $text, 'archive with a comment');

	my $g = mkzip([ ['d.xml', $text] ],
	              ZipComment => "decoy PK\5\6 " . ("\0" x 40));
	reads_back($g, 'd.xml', $text,
		'archive whose comment holds the EOCD signature');
}

# A member that is not there. The archive was understood, so the fast path
# answers "handled, but no such member" rather than declining -- read_table asks
# every workbook for xl/sharedStrings.xml and plenty do not have one, and
# declining would make each of those pay for a second scan.
{
	my $f = mkzip([ ['present.xml', $text] ]);
	my ($handled, $ref) = Stats::LikeR::_unzip_member_fast($f, 'absent.xml');
	is( $handled, 1,     'an absent member is still a handled archive' );
	is( $ref,     undef, 'and comes back undef' );
	is( Stats::LikeR::_unzip_member($f, 'absent.xml'), undef,
		'_unzip_member returns undef for it' );
}

# zip64 is where the fast path stops: the sizes and offsets it needs are in a
# record it does not read, so it hands the archive back.
{
	my $f = mkzip([ ['big.xml', $text, Zip64 => 1] ]);
	unchanged($f, 'big.xml', 'zip64');
}

# `IO::Compress::Zip::zip(..., Append => 1)' does not extend an archive: it
# writes a second, complete one after the first, and the final
# end-of-central-directory record describes only that second archive, with
# offsets counted from where it starts rather than from the start of the file.
# The result reads as one archive only to a reader that scans local headers
# forwards, which is what IO::Uncompress::Unzip does. Following the directory
# lands in the middle of the first archive's compressed data, so the fast path
# declines on the central-directory signature and the fallback answers -- which
# is also why t/read_table.xlsx.t and t/read_table.xlsx.parser.t, whose fixtures
# are built that way, go on exercising the fallback.
{
	my $p = "$dir/appended.zip";
	IO::Compress::Zip::zip(\$text, $p, Name => 'one.xml')
		or die "cannot write $p: $IO::Compress::Zip::ZipError";
	IO::Compress::Zip::zip(\$noise, $p, Name => 'two.xml', Append => 1)
		or die "cannot append to $p: $IO::Compress::Zip::ZipError";
	unchanged($p, 'one.xml', 'concatenated archives, first member');
	unchanged($p, 'two.xml', 'concatenated archives, second member');
}

# Things that are not archives at all. What matters is that _unzip_member still
# answers what it answered before, which is not the same as "no content":
# IO::Uncompress defaults to `Transparent => 1', so a file that is not an
# archive comes back as its own raw bytes rather than failing. _parse_xlsx_sheet
# then finds no <sheetData> in them and read_table comes back empty. That has
# been the behaviour all along; the fast path declines these and changes none
# of it.
{
	my $plain = "$dir/plain.txt";
	open my $fh, '>', $plain or die "cannot write $plain: $!";
	binmode $fh;
	print {$fh} $text or die "cannot write $plain: $!";
	close $fh or die "cannot write $plain: $!";
	unchanged($plain, 'any', 'a file that is not an archive');

	unchanged("$dir/no.such.file", 'any', 'a file that does not exist');

	my $nil = "$dir/nil.zip";
	open my $n, '>', $nil or die "cannot write $nil: $!";
	close $n or die "cannot write $nil: $!";
	unchanged($nil, 'any', 'an empty file');

	# a real archive with its last 40 bytes cut off, so the
	# end-of-central-directory record is gone
	my $whole = mkzip([ ['t.xml', $text] ]);
	my $cut   = "$dir/cut.zip";
	open my $in, '<', $whole or die "cannot read $whole: $!";
	binmode $in;
	my $bytes = do { local $/; <$in> };
	close $in or die "cannot read $whole: $!";
	open my $out, '>', $cut or die "cannot write $cut: $!";
	binmode $out;
	print {$out} substr($bytes, 0, length($bytes) - 40)
		or die "cannot write $cut: $!";
	close $out or die "cannot write $cut: $!";
	unchanged($cut, 't.xml', 'a truncated archive');
}

# End to end: read_table over a workbook whose central directory is intact, so
# every part of it goes through the fast path. write_table writes one of those,
# which is the shortest way to get one.
{
	my $xlsx = "$dir/round.xlsx";
	my @rows = map { { id => $_, name => "n$_", val => $_ / 4 } } 1 .. 300;
	Stats::LikeR::write_table(\@rows, $xlsx, quiet => 1);
	is( (Stats::LikeR::_unzip_member_fast($xlsx, 'xl/worksheets/sheet1.xml'))[0],
		1, 'write_table writes an archive the fast path reads' );
	my $back = Stats::LikeR::read_table($xlsx);
	is( scalar @$back, 300, 'read_table reads it back' );
	is( $back->[0]{name}, 'n1', 'first row survives the round trip' );
	is( $back->[-1]{val}, '75', 'and the last value does' );
}

# The same, for a workbook with a shared-string table: read_table asks for four
# parts (the workbook, its relationships, the strings and the worksheet) and all
# four have to come back through the fast path, with the strings landing in
# _xlsx_sst_xs() as the bytes it expects. write_table's output above has no
# sharedStrings.xml, so this one is assembled here, the way Excel lays one out.
{
	my $ns  = 'http://schemas.openxmlformats.org/spreadsheetml/2006/main';
	my $rns = 'http://schemas.openxmlformats.org/package/2006/relationships';
	my $ons = 'http://schemas.openxmlformats.org/officeDocument/2006/relationships';
	my $sd  = '<row r="1"><c r="A1" t="s"><v>0</v></c><c r="B1" t="s"><v>1</v></c></row>'
	        . '<row r="2"><c r="A2" t="s"><v>2</v></c><c r="B2"><v>42</v></c></row>'
	        . '<row r="3"><c r="A3" t="s"><v>3</v></c><c r="B3"><v>17</v></c></row>';
	my $f = mkzip([
		['[Content_Types].xml',
			'<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
		  . '<Default Extension="xml" ContentType="application/xml"/>'
		  . '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
		  . '</Types>'],
		['_rels/.rels', qq{<Relationships xmlns="$rns">}
		  . qq{<Relationship Id="rId1" Type="$ons/officeDocument" Target="xl/workbook.xml"/>}
		  . '</Relationships>'],
		['xl/workbook.xml', qq{<workbook xmlns="$ns" xmlns:r="$ons">}
		  . '<sheets><sheet name="Data" sheetId="1" r:id="rId1"/></sheets></workbook>'],
		['xl/_rels/workbook.xml.rels', qq{<Relationships xmlns="$rns">}
		  . qq{<Relationship Id="rId1" Type="$ons/worksheet" Target="worksheets/sheet1.xml"/>}
		  . '</Relationships>'],
		['xl/sharedStrings.xml', qq{<sst xmlns="$ns">}
		  . '<si><t>name</t></si><si><t>score</t></si>'
		  . '<si><t>first &amp; only</t></si><si><t>second</t></si></sst>'],
		['xl/worksheets/sheet1.xml',
			qq{<worksheet xmlns="$ns"><sheetData>$sd</sheetData></worksheet>}],
	], _ext => 'xlsx');
	for my $part ('xl/workbook.xml', 'xl/_rels/workbook.xml.rels',
	              'xl/sharedStrings.xml', 'xl/worksheets/sheet1.xml') {
		is( (Stats::LikeR::_unzip_member_fast($f, $part))[0], 1,
			"fast path reads $part" );
	}
	is_deeply( Stats::LikeR::read_table($f),
		[ { name => 'first & only', score => '42' },
		  { name => 'second',       score => '17' } ],
		'read_table reads a shared-string workbook through the fast path' );
}

done_testing();
