#!/usr/bin/env perl
# write_table to .gz and .bz2 files.
#
# A name ending .gz or .bz2 is written through a compressing PerlIO::via layer
# (Stats::LikeR::_Compress and its two subclasses in lib/Stats/LikeR.pm; the
# XS pushes it in write_table and pops it to finish the stream).
#
# Provenance. The frames and what is asked of them are pandas 3.0.4's
# (/home/con/.pyenv/versions/3.14.2/lib/python3.14/site-packages/pandas):
#
#   tests/io/test_compression.py
#     test_compression_size: 100 copies of the rows [0.123456, 0.234567,
#       0.567567] and [12.32112, 123123.2, 321321.2] as X, Y, Z, which must
#       come out smaller compressed than plain
#     test_dataframe_compression_defaults_to_infer (GH22004):
#       [[1.0, 0, -4], [3.4, 5, 2]] as X, Y, Z, written to compressed.<ext>
#       with no compression argument and read back equal
#   tests/io/formats/test_to_csv.py
#     test_to_csv_compression (gh-15008): {"A": [1]} with its index, written
#       to a name with the extension and read back equal
#     test_to_csv_iterative_compression_name (GH 38714): 1.1 * arange(120)
#       as 30 x 4, columns A..D, index i-0 .. i-29, written a row at a time
#       (chunksize=1); here every row is its own write already, since the XS
#       prints row by row
#
# pandas writes the index as a column, which write_table does as
# 'row.names'; its read_csv(index_col=0) is read_table's 'hoh' on that column.
# pandas compares frames of numbers; write_table writes the strings perl makes
# of them, so each frame is compared here with what the same call writes to a
# plain file -- the compressed file must hold exactly those bytes -- and with
# what read_table reads back from it.
#
# The rest -- that the bytes decompress with zlib and bzip2 directly and not
# only through read_table, that there is exactly one member, that the output
# is the same every time, the default sep from the name, rows over many of
# the layer's 8 KB writes, a croak partway, a full disk, and each refusal -- is
# this module's own surface.
require 5.010001;
use strict;
use warnings FATAL => 'all';
use Test::More;
use File::Temp ();
use File::Spec ();
use Compress::Raw::Zlib ();
use Compress::Raw::Bzip2 ();
use Stats::LikeR qw(read_table write_table);

our $HAVE_LEAKTRACE;
BEGIN {
	$HAVE_LEAKTRACE = eval {
		require Test::LeakTrace;
		Test::LeakTrace->import('no_leaks_ok');
		1;
	} ? 1 : 0;
}

my $dir = File::Temp::tempdir(CLEANUP => 1);
sub path { File::Spec->catfile($dir, @_) }

# The line end a plain write_table file gets: PerlIO_open()'s default layers,
# which are :crlf where perl is a CRLF shop (Windows), and a compressed file
# holds the same text. Literals below are written with \n and put through nl().
my $NL = do {
	open my $fh, '>', path('nl.probe') or die "cannot write a probe: $!\n";
	my $crlf = grep { $_ eq 'crlf' } PerlIO::get_layers($fh);
	close $fh;
	$crlf ? "\r\n" : "\n";
};
sub nl { (my $s = shift) =~ s/\n/$NL/g; $s }

sub slurp {
	my ($path) = @_;
	open my $fh, '<', $path or die "cannot read \"$path\": $!\n";
	binmode $fh;
	local $/;
	my $bytes = <$fh>;
	close $fh;
	return $bytes;
}

# The text of a .gz, inflated by zlib directly, and how many bytes follow
# its first member (0 for a file of one member).
sub gunzip {
	my ($bytes) = @_;
	my ($z) = Compress::Raw::Zlib::Inflate->new(
		-WindowBits => Compress::Raw::Zlib::WANT_GZIP(), -ConsumeInput => 1);
	my $out = '';
	my $status = $z->inflate($bytes, $out);
	return ($status == Compress::Raw::Zlib::Z_STREAM_END() ? $out : undef,
		length $bytes);
}

sub bunzip {
	my ($bytes) = @_;
	my ($z) = Compress::Raw::Bunzip2->new(1, 1, 0, 0);
	my $out = '';
	my $status = $z->bzinflate($bytes, $out);
	return ($status == Compress::Raw::Bzip2::BZ_STREAM_END() ? $out : undef,
		length $bytes);
}

# Write $data plain and compressed with the same options, and check that the
# compressed file is that text, in one member, and reads back as it does.
sub same_as_plain {
	my ($what, $data, $stem, %opt) = @_;
	my $plain = path("$stem");
	write_table($data, $plain, quiet => 1, %opt);
	my $text = slurp($plain);
	for my $c ([ 'gz', \&gunzip ], [ 'bz2', \&bunzip ]) {
		my $f = path("$stem.$c->[0]");
		write_table($data, $f, quiet => 1, %opt);
		my ($got, $rest) = $c->[1]->(slurp($f));
		is $got, $text, "$what, .$c->[0]: the text is the plain file's";
		is $rest, 0, "$what, .$c->[0]: one member, nothing after it";
		my %rt = $opt{'row.names'}
			? ('output.type' => 'hoh', 'row.names' => $opt{'row.names'}) : ();
		is_deeply read_table($f, %rt), read_table($plain, %rt),
			"$what, .$c->[0]: read_table reads it as the plain file";
	}
	return $text;
}

# test_dataframe_compression_defaults_to_infer (GH22004)
same_as_plain('GH22004',
	[ [qw(X Y Z)], [ 1.0, 0, -4 ], [ 3.4, 5, 2 ] ], 'compressed.csv');

# test_to_csv_compression (gh-15008): the index is written, and read back
{
	my $text = same_as_plain('gh-15008', { 0 => { A => 1 } }, 'gh15008.csv',
		'row.names' => 'idx');
	is $text, nl("idx,A\n0,1\n"),'gh-15008: the index is a column';
}

# test_to_csv_iterative_compression_name (GH 38714)
{
	my %df;
	for my $i (0 .. 29) {
		$df{"i-$i"} = { map { (qw(A B C D))[$_] => 1.1 * (4 * $i + $_) } 0 .. 3 };
	}
	same_as_plain('GH 38714', \%df, 'gh38714.csv', 'row.names' => 'index');
}

# test_compression_size: smaller compressed than plain
{
	my @rows = ([qw(X Y Z)],
		map { ([ 0.123456, 0.234567, 0.567567 ], [ 12.32112, 123123.2, 321321.2 ]) } 1 .. 100);
	same_as_plain('test_compression_size', \@rows, 'size.csv');
	my $plain = -s path('size.csv');
	cmp_ok -s path("size.csv.$_"), '<', $plain, "test_compression_size: .$_ is smaller"
		for qw(gz bz2);
}

# Rows over many of the layer's 8 KB writes and the reader's 64 KB reads,
# with fields that need quoting and hold line breaks; every shape.
{
	my @aoh = map { { n => $_, sq => $_ * $_, s => "q\"$_\nr$_" } } 1 .. 20000;
	my $text = same_as_plain('20000 rows, aoh', \@aoh, 'big.csv');
	cmp_ok length $text, '>', 4 * (1 << 16), 'the text spans many writes';
	my %hoa = (n => [ 1 .. 5000 ], s => [ map { "x,$_" } 1 .. 5000 ]);
	same_as_plain('hoa', \%hoa, 'hoa.csv');
	same_as_plain('flat hash', { a => 1, b => 'two' }, 'flat.csv');
}

# The name decides the default sep from the part before the suffix, and an
# explicit sep still wins.
{
	my @d = ({ a => 1, b => 2 });
	for my $case ([ 't.tsv.gz', "a\tb\n1\t2\n" ], [ 't.TSV.GZ', "a\tb\n1\t2\n" ],
			[ 't.tsv.bz2', "a\tb\n1\t2\n" ], [ 't.csv.BZ2', "a,b\n1,2\n" ],
			[ 't.gz', "a,b\n1,2\n" ]) {
		my ($name, $want) = ($case->[0], nl($case->[1]));
		my $f = path($name);
		write_table(\@d, $f, quiet => 1);
		my ($got) = $name =~ /gz\z/i ? gunzip(slurp($f)) : bunzip(slurp($f));
		is $got, $want, "$name: the default sep is the inner name's";
	}
	my $f = path('semi.tsv.gz');
	write_table(\@d, $f, quiet => 1, sep => ';');
	is((gunzip(slurp($f)))[0], nl("a;b\n1;2\n"), 'an explicit sep wins over .tsv.gz');
}

# The same table makes the same bytes: zlib's gzip header carries no name and
# an mtime of 0, and bzip2's none at all.
for my $ext (qw(gz bz2)) {
	my @d = map { { a => $_ } } 1 .. 100;
	write_table(\@d, path("one.$ext"), quiet => 1);
	sleep 1 if $ext eq 'gz';	# a header mtime would now differ
	write_table(\@d, path("two.$ext"), quiet => 1);
	is slurp(path("one.$ext")), slurp(path("two.$ext")),
		".$ext: the same table, the same bytes";
}
is substr(slurp(path('one.gz')), 4, 4), "\0\0\0\0", 'the gzip header mtime is 0';

# A croak partway -- here a nested reference in the last row -- leaves a file
# whose stream never ends, which read_table refuses; it does not leave a
# complete file holding the rows before it.
# That holds for a croak on the first row as well as on the 20,001st: bzip2
# would otherwise not yet have written a byte, and an empty file is an empty
# table to read_table, not a broken one (see _Bzip2::DEFLATE).
for my $ext (qw(gz bz2)) {
	for my $n (20000, 0) {
		my $f = path("partial$n.csv.$ext");
		my @d = ([qw(a b)], (map { [ $_, $_ ] } 1 .. $n), [ 1, [2] ]);
		eval { write_table(\@d, $f, quiet => 1) };
		is $@, "write_table: Cannot write nested reference types to table\n",
			".$ext, after $n rows: the nested reference croaks";
		cmp_ok -s $f, '>', 0, ".$ext, after $n rows: the partial file is not empty";
		eval { read_table($f) };
		my $codec = $ext eq 'gz' ? 'gzip' : 'bzip2';
		is $@, "read_table: \"$f\" ends in the middle of its $codec data; it is truncated\n",
			".$ext, after $n rows: and read_table refuses it as truncated";
	}
}

# Refusals: only delimited text is compressed, and .bgz is not plain gzip.
{
	my @d = ({ a => 1 });
	for my $case ([ 'x.tex.gz' ], [ 'x.xlsx.bz2' ], [ 'x.gz', tex => 1 ],
			[ 'x.csv.bz2', xlsx => 1 ]) {
		my ($name, @opt) = @$case;
		my $f = path($name);
		eval { write_table(\@d, $f, quiet => 1, @opt) };
		is $@, "write_table: '$f' names a compressed file, and only delimited "
		     . "text is written compressed, not LaTeX or .xlsx\n",
			"$name @opt: refused";
		ok !-e $f, "$name @opt: and nothing is written";
	}
	for my $name (qw(x.tsv.bgz x.BGZ x.bgz.gz)) {
		my $f = path($name);
		eval { write_table(\@d, $f, quiet => 1) };
		is $@, "write_table: '$f' names a bgzip (BGZF) file, which write_table "
		     . "does not write; name it .gz for gzip\n", "$name: refused";
	}
	# tex => 0 on a .tex.gz name is delimited, and so is compressed
	my $f = path('y.tex.gz');
	write_table(\@d, $f, quiet => 1, tex => 0);
	is((gunzip(slurp($f)))[0], nl("a\n1\n"), 'tex => 0 with a .tex.gz name: gzipped text');
}

# A write that cannot be finished croaks. /dev/full takes the open and fails
# every write with ENOSPC; it is reached through a link named .gz.
SKIP: {
	skip 'no /dev/full here', 4 unless -c '/dev/full' && -w _;
	require Errno;
	for my $ext (qw(gz bz2)) {
		my $f = path("full.$ext");
		skip 'symlink() is not available', 4
			unless eval { symlink('/dev/full', $f) };
		# The reason is the system's, formatted by $! as the XS formats it.
		my $enospc = do { local $! = Errno::ENOSPC(); "$!" };
		eval { write_table([ { a => 1 } ], $f, quiet => 1) };
		is $@, "write_table: could not finish writing '$f': $enospc\n", ".$ext: a full disk croaks, and says why";
		eval { write_table([ map { { a => $_ } } 1 .. 50000 ], $f, quiet => 1) };
		is $@, "write_table: could not finish writing '$f': $enospc\n",
			".$ext: and so it does when a WRITE fails partway";
	}
}

# The confirmation line names the file as given.
{
	my $f = path('said.csv.gz');
	my $out = '';
	{
		pipe my $r, my $w or die "pipe: $!\n";
		open my $save, '>&', \*STDOUT or die "dup: $!\n";
		open STDOUT, '>&', $w or die "redirect: $!\n";
		write_table([ { a => 1 } ], $f);
		open STDOUT, '>&', $save or die "restore: $!\n";
		close $w;
		binmode $r;
		local $/;
		$out = <$r>;
	}
	# STDOUT's line end is perl's layers' doing, not write_table's: on MSWin32
	# the smoker for 0.321 read "\r\n" back through this pipe. The name is
	# what is under test here.
	$out =~ s/\r\n/\n/g;
	is $out, "wrote \e[30;46m$f\e[0m\n", 'a compressed write announces itself as any other';
}

SKIP: {
	skip 'Test::LeakTrace not installed', 4 unless $HAVE_LEAKTRACE;
	skip 'running under Devel::Cover', 4 if $INC{'Devel/Cover.pm'};
	my @d = map { { a => $_, b => "x$_" } } 1 .. 50;
	write_table(\@d, path('warm.gz'), quiet => 1);	# loads the layers first
	write_table(\@d, path('warm.bz2'), quiet => 1);
	no_leaks_ok { write_table(\@d, path('leak.csv.gz'), quiet => 1) }
		'no leaks: a gzip write';
	no_leaks_ok { write_table(\@d, path('leak.csv.bz2'), quiet => 1) }
		'no leaks: a bzip2 write';
	no_leaks_ok { eval { write_table([ [ 'a' ], [ [1] ] ], path('leak.bad.gz'), quiet => 1) } }
		'no leaks: a croak partway';
	no_leaks_ok { eval { write_table(\@d, path('leak.tex.gz'), quiet => 1) } }
		'no leaks: a refused name';
}

done_testing();
