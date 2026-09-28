#!/usr/bin/env perl
# read_table on gzip- and bzip2-compressed files.
#
# A compressed file is recognised by its first bytes, as R's file() recognises
# one for read.table, and is read through a decompressing PerlIO::via layer
# (_sniff_compression() and _open_decompressed() in lib/Stats/LikeR.pm).
#
# Provenance. The fixtures are R 4.6.1's own, written by
# t/read_table.compressed.R (which says how to re-run it) exactly as R's
# tests/reg-tests-1b.R writes its compressed input:
#
#   * "tests of read.table with different types of compressed input":
#     datasets' data/morley.tab through gzfile() and bzfile(), and
#     stopifnot(identical(read.table(tf), morley)) for each. Here the same
#     files must read exactly as t/morley.tab does, the plain copy, with
#     auto.row.names standing in for read.table's rule that a header one
#     field short names the rows. The two rows pinned below are R's
#     print(morley[c(1, 100), ]): 001 is 1 1 850, 100 is 5 20 870.
#   * "tests of append mode on compressed connections": 1:50 written through
#     gzfile(tf, "w"), 51:70 through gzfile(tf, "a"), and
#     stopifnot(length(readLines(tf)) == 70); the same through bzfile(). The
#     append starts a second member, so these are R's multi-member files.
#   * morley.tab through htslib's bgzip, which is not in R's suite: BGZF is
#     how most genomic tables are compressed, and holds a data block and the
#     empty end-of-file block, two members again.
#
# pandas 3.0.4's tests/io/parser/test_compression.py supplies the cases about
# names, with its adaptations forced by read_table sniffing where pandas'
# compression='infer' goes by the extension:
#
#   * test_compression with filename=None: a compressed file with no suffix
#     is still read, here because its bytes say what it is;
#   * test_ignore_compression_extension: a plain file named .csv.zip read with
#     compression=None is text. Here a plain file named .gz is text with no
#     option at all, since its bytes are not gzip's.
#
# R's PR#18768, the fix in comp_type_from_memory() (src/main/connections.c)
# that made a text file beginning "BZh" stop being taken for bzip2, is the
# source of that case; the bzip2 test there, and here, runs to ten bytes.
#
# The rest -- each output shape, filters, the commented-header rescue, a
# byte-order mark, CRLF, the caller's $/, many members, NUL padding, every
# truncation of a fixture, a corrupted CRC, trailing data, an empty stream,
# and each message -- is this module's own surface. Those files are made here
# with Compress::Raw::Zlib and Compress::Raw::Bzip2, the modules the layer
# reads them with, and their expected values are the plain text they were
# made from.
require 5.010001;
use strict;
use warnings FATAL => 'all';
use Test::More;
use File::Temp ();
use File::Spec ();
use FindBin ();
use Compress::Raw::Zlib ();
use Stats::LikeR qw(read_table);

our $HAVE_LEAKTRACE;
BEGIN {
	$HAVE_LEAKTRACE = eval {
		require Test::LeakTrace;
		Test::LeakTrace->import('no_leaks_ok');
		1;
	} ? 1 : 0;
}

my $dir = File::Temp::tempdir(CLEANUP => 1);
sub t_file { File::Spec->catfile($FindBin::Bin, @_) }

sub fixture {
	my ($name, $bytes) = @_;
	my $path = File::Spec->catfile($dir, $name);
	open my $fh, '>', $path or die "cannot write \"$path\": $!\n";
	binmode $fh;
	print {$fh} $bytes;
	close $fh or die "cannot close \"$path\": $!\n";
	return $path;
}

sub slurp {
	my ($path) = @_;
	open my $fh, '<', $path or die "cannot read \"$path\": $!\n";
	binmode $fh;
	local $/;
	my $bytes = <$fh>;
	close $fh;
	return $bytes;
}

# One gzip member holding $text.
sub gz {
	my ($text) = @_;
	my ($z, $err) = Compress::Raw::Zlib::Deflate->new(
		-WindowBits => Compress::Raw::Zlib::WANT_GZIP(), -AppendOutput => 1);
	die "deflate: $err\n" unless $z;
	my $out = '';
	$z->deflate($text, $out) == Compress::Raw::Zlib::Z_OK() or die "deflate\n";
	$z->flush($out) == Compress::Raw::Zlib::Z_OK() or die "flush\n";
	return $out;
}

# Compress::Raw::Bzip2 is core from perl 5.10.1, the oldest supported, and a
# declared prerequisite, but _open_decompressed() loads it only for a bzip2
# file and says so if it is missing, since some vendors split core modules
# into packages of their own. Before it is loaded, one read is made with the
# load forced to fail, which is the one way to reach that message.
{
	my $f = t_file('morley.tab.bz2');
	local @INC = (sub { die "no Compress::Raw::Bzip2 here\n"
		if $_[1] eq 'Compress/Raw/Bzip2.pm'; return }, @INC);
	local $INC{'Compress/Raw/Bzip2.pm'};
	delete $INC{'Compress/Raw/Bzip2.pm'};
	eval { read_table($f, sep => qr/\s+/) };
	is $@, "read_table: \"$f\" is bzip2-compressed, and reading it needs "
	     . "Compress::Raw::Bzip2, which is not installed\n",
		'bzip2 without Compress::Raw::Bzip2: the message says what is missing';
}
require Compress::Raw::Bzip2;

# One bzip2 stream holding $text.
sub bz {
	my ($text) = @_;
	my ($z, $err) = Compress::Raw::Bzip2->new(1, 9, 0, 0);
	die "bzdeflate: $err\n" unless $z;
	my $out = '';
	# bzdeflate() refuses an empty buffer; bzclose() alone is the empty stream
	length $text == 0
		or $z->bzdeflate($text, $out) == Compress::Raw::Bzip2::BZ_RUN_OK()
		or die "bzdeflate\n";
	$z->bzclose($out) == Compress::Raw::Bzip2::BZ_STREAM_END()
		or die "bzclose\n";
	return $out;
}

my %morley = (sep => qr/\s+/, 'auto.row.names' => 1);
my $plain  = t_file('morley.tab');

# R's identical(read.table(tf), morley), for each compressed copy and output
# shape, and each fixture must be what its name says rather than text that
# happens to read the same.
{
	my %magic = ('morley.tab.gz' => "\x1f\x8b", 'morley.tab.bgz' => "\x1f\x8b",
		'morley.tab.bz2' => 'BZh');
	for my $name (sort keys %magic) {
		my $f = t_file($name);
		is substr(slurp($f), 0, length $magic{$name}), $magic{$name},
			"$name is compressed";
		for my $otype (qw(aoh aoa hoa)) {
			is_deeply read_table($f, %morley, 'output.type' => $otype),
				read_table($plain, %morley, 'output.type' => $otype),
				"$name reads as morley.tab does ($otype)";
		}
		my $hoh = read_table($f, %morley, 'output.type' => 'hoh',
			'row.names' => 'row_name');
		is scalar(keys %$hoh), 100, "$name: 100 rows, as dim(morley)";
		is_deeply [ @{ $hoh->{'001'} }{qw(Expt Run Speed)} ], [ 1, 1, 850 ],
			"$name: morley['001', ] is 1 1 850";
		is_deeply [ @{ $hoh->{'100'} }{qw(Expt Run Speed)} ], [ 5, 20, 870 ],
			"$name: morley['100', ] is 5 20 870";
		# a filter takes the per-row perl path instead of the parser's plan
		is_deeply read_table($f, %morley, filter => { Expt => sub { $_ == 3 } }),
			read_table($plain, %morley, filter => { Expt => sub { $_ == 3 } }),
			"$name: a filter sees the same rows";
	}
}

# R's append-mode files: two members, all 70 lines.
{
	my @want = ([ 'V1' ], map { [ $_ ] } 1 .. 70);
	for my $name (qw(append70.gz append70.bz2)) {
		my $f = t_file($name);
		is_deeply read_table($f, header => 0, 'output.type' => 'aoa'), \@want,
			"$name: both members are read, 70 lines as readLines() gives";
	}
	# Cut where the first member ends, the file is a whole gzip file of one
	# member, and reads as the 50 lines that member holds.
	my $bytes = slurp(t_file('append70.gz'));
	my $first = Compress::Raw::Zlib::Inflate->new(
		-WindowBits => Compress::Raw::Zlib::WANT_GZIP(), -ConsumeInput => 1);
	my ($rest, $out) = ($bytes, '');
	$first->inflate($rest, $out) == Compress::Raw::Zlib::Z_STREAM_END()
		or die "append70.gz: the first member does not end\n";
	my $f = fixture('first50.gz', substr($bytes, 0, length($bytes) - length $rest));
	is_deeply read_table($f, header => 0, 'output.type' => 'aoa'),
		[ [ 'V1' ], map { [ $_ ] } 1 .. 50 ],
		'append70.gz cut at the member boundary: the first 50 lines';
}

# The name decides nothing. pandas' test_compression with filename=None, and
# test_ignore_compression_extension; then the default sep, which the
# extension does pick, from the name of the text inside.
{
	my $csv = "a,b\n1,x\n2,y\n";
	my $want = [ { a => 1, b => 'x' }, { a => 2, b => 'y' } ];
	is_deeply read_table(fixture('no_suffix', gz($csv))), $want,
		'gzip with no suffix is still read';
	is_deeply read_table(fixture('plain.csv.gz', $csv)), $want,
		'a plain file named .gz is read as text';
	is_deeply read_table(fixture('plain.csv.bz2', $csv)), $want,
		'a plain file named .bz2 is read as text';
	# R's PR#18768: "BZh" and a digit is not enough to be bzip2
	is_deeply read_table(fixture('bzh.csv', "BZh9,b\n1,2\n")),
		[ { BZh9 => 1, b => 2 } ], 'text that begins "BZh9" is text';
	my $tsv = "a\tb\n1\tx\n2\ty\n";
	is_deeply read_table(fixture('t.tsv.gz', gz($tsv))), $want,
		'x.tsv.gz is tab-separated by default';
	is_deeply read_table(fixture('t.TSV.BGZ', gz($tsv))), $want,
		'x.tsv.bgz too, whatever the case';
	is_deeply read_table(fixture('t.csv.gz', gz($tsv))),
		[ { "a\tb" => "1\tx" }, { "a\tb" => "2\ty" } ],
		'x.csv.gz is comma-separated by default';
	{
		is_deeply read_table(fixture('t.tsv.bz2', bz($tsv))), $want,
			'x.tsv.bz2 is tab-separated by default';
	}
}

# What the parser does to text it reads itself, it does to decompressed text.
{
	my $csv = "\xEF\xBB\xBFid,v\r\n1,\"two\r\nlines\"\r\n3,x\r\n";
	is_deeply read_table(fixture('bom.csv.gz', gz($csv))),
		read_table(fixture('bom.csv', $csv)),
		'a byte-order mark, CRLF and a quoted line break, as in a plain file';
	my $hdr = "# a,b\n1,2\n";
	is_deeply read_table(fixture('hdr.csv.gz', gz($hdr))), [ { a => 1, b => 2 } ],
		'a commented-out header is recovered from a compressed file';
	my $f = fixture('rs.csv.gz', gz("a,b\n1,2\n3,4\n"));
	my $want = [ { a => 1, b => 2 }, { a => 3, b => 4 } ];
	{
		local $/;
		is_deeply read_table($f), $want, 'under local $/, still one row a line';
	}
	{
		local $/ = \2;
		is_deeply read_table($f), $want, 'under $/ = \2, still one row a line';
	}
}

# Many members, rows that run across the layer's 64 KB reads, and NUL
# padding; each checked against the plain text it was made from.
{
	my @rows = map { join(',', $_, $_ * $_, "\"q$_\nr$_\"") . "\n" } 1 .. 20000;
	my $text = "n,sq,s\n" . join '', @rows;
	my $want = read_table(fixture('big.csv', $text));
	cmp_ok length $text, '>', 4 * (1 << 16), 'the text spans several reads';
	is_deeply read_table(fixture('big.csv.gz', gz($text))), $want,
		'one member, many reads';
	my $members = gz("n,sq,s\n") . join '', map { gz($_) } @rows[0 .. 999];
	is_deeply read_table(fixture('members.csv.gz', $members)),
		[ @$want[0 .. 999] ], 'a member per row, 1001 members';
	# the BGZF end-of-file block, SAMv1.pdf section 4.1.2
	my $bgzf_eof = "\x1f\x8b\x08\x04\x00\x00\x00\x00\x00\xff\x06\x00\x42\x43"
	             . "\x02\x00\x1b\x00\x03\x00\x00\x00\x00\x00\x00\x00\x00\x00";
	is_deeply read_table(fixture('eof.csv.gz', gz($text) . $bgzf_eof)), $want,
		'an empty member at the end, as bgzip writes';
	is_deeply read_table(fixture('pad.csv.gz', gz("a\n1\n") . ("\0" x 5000)
		. gz("2\n") . "\0\0")), [ { a => 1 }, { a => 2 } ],
		'NUL padding between and after members is skipped';
	{
		is_deeply read_table(fixture('big.csv.bz2', bz($text))), $want,
			'bzip2: one stream, many reads';
		is_deeply read_table(fixture('streams.csv.bz2', bz("n,sq,s\n")
			. join '', map { bz($_) } @rows[0 .. 199])),
			[ @$want[0 .. 199] ], 'bzip2: a stream per row, as pbzip2 writes';
	}
}

# An empty stream is an empty file, as it is to R and to pandas.
{
	is_deeply read_table(fixture('empty.csv.gz', gz(''))), [],
		'an empty gzip member reads as an empty file';
	is_deeply read_table(fixture('hdronly.csv.gz', gz("a,b\n")), 'output.type' => 'hoa'),
		{}, 'a header and no rows, compressed';
	{
		is_deeply read_table(fixture('empty.csv.bz2', bz(''))), [],
			'an empty bzip2 stream reads as an empty file';
	}
}

# Damage. A truncated file is refused wherever it is cut, never read short:
# every prefix of morley.tab.gz long enough to be taken for gzip (two bytes),
# and of morley.tab.bz2 long enough to be taken for bzip2 (ten).
{
	my $gz = slurp(t_file('morley.tab.gz'));
	my @bad;
	for my $len (2 .. length($gz) - 1) {
		my $f = fixture('cut.gz', substr($gz, 0, $len));
		eval { read_table($f, %morley); 1 } and push @bad, $len;
		push @bad, "$len: $@" if $@ && $@ !~ /\Aread_table: "\Q$f\E" (?:ends in the middle of its gzip data; it is truncated|is not valid gzip data \(.+\))\n\z/;
	}
	is_deeply \@bad, [], 'every truncation of morley.tab.gz is refused';
	{
		my $bz = slurp(t_file('morley.tab.bz2'));
		@bad = ();
		for my $len (10 .. length($bz) - 1) {
			my $f = fixture('cut.bz2', substr($bz, 0, $len));
			eval { read_table($f, %morley); 1 } and push @bad, $len;
			push @bad, "$len: $@" if $@ && $@ !~ /\Aread_table: "\Q$f\E" (?:ends in the middle of its bzip2 data; it is truncated|is not valid bzip2 data \(.+\))\n\z/;
		}
		is_deeply \@bad, [], 'every truncation of morley.tab.bz2 is refused';
	}

	my $csv = "a,b\n1,2\n";
	my $member = gz($csv);
	# RFC 1952 section 2.3.1: the trailer is CRC32 then ISIZE, 4 bytes each
	for my $at ([ 'CRC-32', -8 ], [ 'length', -4 ]) {
		my $bytes = $member;
		substr($bytes, $at->[1], 1) ^= "\x01";
		my $f = fixture('trailer.gz', $bytes);
		eval { read_table($f) };
		like $@, qr/\Aread_table: "\Q$f\E" is not valid gzip data \(.+\)\n\z/,
			"a wrong $at->[0] in the trailer is corrupt data";
	}
	my $f = fixture('method.gz', "\x1f\x8b\x09" . substr($member, 3));
	eval { read_table($f) };
	like $@, qr/\Aread_table: "\Q$f\E" is not valid gzip data \(.+\)\n\z/,
		'a compression method other than deflate is corrupt data';
	$f = fixture('garbage.gz', $member . "trailing text\n");
	eval { read_table($f) };
	is $@, "read_table: \"$f\" has data after its last gzip member that is not gzip\n",
		'text after the last member is refused, not read as rows';
	$f = fixture('garbage1.gz', $member . "\0\0x");
	eval { read_table($f) };
	like $@, qr/has data after its last gzip member/,
		'so is a byte after NUL padding';
	$f = fixture('half.gz', $member . "\x1f");
	eval { read_table($f) };
	like $@, qr/has data after its last gzip member/,
		'so is one byte of a magic number';
	{
		$f = fixture('garbage.bz2', bz($csv) . 'x');
		eval { read_table($f) };
		is $@, "read_table: \"$f\" has data after its last bzip2 member that is not bzip2\n",
			'bzip2: text after the last stream is refused';
	}
}

# A croak from inside the read -- here a filter's -- leaves nothing open, and
# the next read of the same file is whole.
{
	my $f = fixture('die.csv.gz', gz("a\n1\n2\n"));
	eval { read_table($f, filter => { a => sub { die "stop\n" if $_ == 2; 1 } }) };
	is $@, "stop\n", "a filter's die comes through the layer";
	is_deeply read_table($f), [ { a => 1 }, { a => 2 } ], 'and the file reads again';
}

SKIP: {
	skip 'Test::LeakTrace not installed', 3 unless $HAVE_LEAKTRACE;
	skip 'running under Devel::Cover', 3 if $INC{'Devel/Cover.pm'};
	my $f = fixture('leak.csv.gz', gz("a,b\n1,2\n3,4\n"));
	my $bad = fixture('leak.bad.gz', substr(gz("a,b\n1,2\n3,4\n"), 0, 12));
	read_table($f);	# loads PerlIO::via and the layer's classes first
	no_leaks_ok { read_table($f) } 'no leaks: a gzip read';
	no_leaks_ok { read_table($f, filter => { a => sub { 1 } }) }
		'no leaks: a gzip read with a filter';
	no_leaks_ok { eval { read_table($bad) } } 'no leaks: a truncated gzip file';
}

done_testing();
