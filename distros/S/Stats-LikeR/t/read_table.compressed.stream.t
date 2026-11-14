#!/usr/bin/env perl
# read_table on a compressed file holds one block of its text at a time.
#
# A .gz or .bz2 is read through a PerlIO::via layer whose FILL returns the next
# 64 KB or so of decompressed text (Stats::LikeR::_Decompress in
# lib/Stats/LikeR.pm). PerlIO::via leaves each of those return values as a
# mortal, and up to 0.3418 _parse_csv_file() freed no temporaries between
# rows, so every block was held until the parse ended and a compressed read
# cost the whole decompressed text on top of the table: a filtered read of a
# 400 MB CSV that kept 20,475 of 7.8 million rows peaked at 30 MB from the
# plain file and at 422 MB from its .gz (426 MB from its .bz2).
#
# Provenance. There is no reference case to take: R's gzfile() and pandas'
# compression= are streams with no per-block scalar to count, and neither
# suite measures memory. What is counted here is this module's own blocks.
# FILL is wrapped so that each block it returns is an object that stringifies
# to the block, which is all PerlIO::via asks of it (SvPV(), in
# PerlIOVia_fill(), ext/PerlIO-via/via.xs, perl 5.10.1 and 5.44.0), and whose
# DESTROY counts it out. A filter, called for every row, then sees how many
# blocks are alive at that moment. With the fix that is the one being read,
# and one more while the next is handed over; without it, every block read so
# far.
#
# The files are made here with Compress::Raw::Zlib and Compress::Raw::Bzip2,
# the modules the layer reads them with, and the expected table is the plain
# text they were made from.
require 5.010001;
use strict;
use warnings FATAL => 'all';
use Test::More;
use File::Temp ();
use File::Spec ();
use Compress::Raw::Zlib ();
use Stats::LikeR qw(read_table);

my $dir = File::Temp::tempdir(CLEANUP => 1);
sub fixture {
	my ($name, $bytes) = @_;
	my $path = File::Spec->catfile($dir, $name);
	open my $fh, '>', $path or die "cannot write \"$path\": $!\n";
	binmode $fh;
	print {$fh} $bytes;
	close $fh or die "cannot close \"$path\": $!\n";
	return $path;
}

# 40,000 rows of 26 bytes: 1 MB of text, which the layer hands over in at
# least 16 blocks of 64 KB (its $BUFSIZE). The numbers are a fixed sequence,
# not rand(), so the file is the same on every run.
my $n_rows = 40_000;
my $x = 4321;
my @val = map { $x = ($x * 1103515245 + 12345) % 2147483648; sprintf '%010d', $x } 1 .. $n_rows;
my $text = join '', "id,value,pad\n", map { sprintf "%08d,%s,pad\n", $_, $val[$_ - 1] } 1 .. $n_rows;

my ($made, $freed) = (0, 0);
{
	package Local::Block;
	use overload '""' => sub { ${ $_[0] } }, fallback => 1;
	sub DESTROY { $freed++ }
}
my $fill = \&Stats::LikeR::_Decompress::FILL;
{
	no warnings 'redefine';
	*Stats::LikeR::_Decompress::FILL = sub {
		my $out = $fill->(@_);
		return undef unless defined $out;
		$made++;
		return bless \$out, 'Local::Block';
	};
}

my %file;
{
	my ($d) = Compress::Raw::Zlib::Deflate->new(-WindowBits => Compress::Raw::Zlib::WANT_GZIP());
	my ($out, $tail, $copy) = ('', '', $text);
	$d->deflate($copy, $out);
	$d->flush($tail);
	$file{gzip} = fixture('t.csv.gz', $out . $tail);
}
if (eval { require Compress::Raw::Bzip2; 1 }) {
	my ($d) = Compress::Raw::Bzip2->new(1, 9, 0);
	my ($out, $tail, $copy) = ('', '', $text);
	$d->bzdeflate($copy, $out);
	$d->bzclose($tail);
	$file{bzip2} = fixture('t.csv.bz2', $out . $tail);
}

for my $codec (qw(gzip bzip2)) {
	SKIP: {
		# the module's absence, not a reference implementation's: read_table
		# itself reports a .bz2 as unreadable without it
		skip "Compress::Raw::Bzip2 not installed", 8 unless $file{$codec};

		# a filter: called per row, by S_filter_row()
		($made, $freed) = (0, 0);
		my ($worst, $rows) = (0, 0);
		my $kept = read_table($file{$codec}, output_type => 'hoa', filter => { id => sub {
			$rows++;
			my $alive = $made - $freed;
			$worst = $alive if $alive > $worst;
			return $_ % 1000 == 0;
		} });
		is($rows, $n_rows, "$codec, filtered: the filter saw every row");
		is_deeply($kept->{value}, [ map { $val[$_ * 1000 - 1] } 1 .. $n_rows / 1000 ],
			"$codec, filtered: the rows kept are the file's");
		cmp_ok($made, '>=', 16, "$codec, filtered: the text came in at least 16 blocks ($made)");
		# 2: the block being read, and the next for the moment it is handed
		# over. Observed 1 on perl 5.44.0; up to 0.3418 it was every block.
		cmp_ok($worst, '<=', 2, "$codec, filtered: at most 2 blocks alive at any row ($worst)");
		is($freed, $made, "$codec, filtered: every block is freed by the end");

		# no filter: nothing runs between rows, so only the end can be seen,
		# and the table must be the file's
		($made, $freed) = (0, 0);
		my $all = read_table($file{$codec}, output_type => 'hoa');
		is_deeply($all->{value}, \@val, "$codec: an unfiltered read returns every value");
		is($freed, $made, "$codec: every block is freed by the end");
		# a read that dies partway frees what it held
		($made, $freed) = (0, 0);
		eval { read_table($file{$codec}, filter => { id => sub { die "stop\n" if $_ == 30_000; 0 } }) };
		is($freed, $made, "$codec: a read that dies in a filter frees its blocks ($made)");
	}
}

done_testing;
