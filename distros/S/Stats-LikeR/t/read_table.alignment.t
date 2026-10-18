#!/usr/bin/env perl
# The words of read_table's "Alignment error", which say what a ragged row was
# compared with and, where the cause is most likely a wrong sep, say that too.
#
# Up to 0.3217 the message always ended "(N fields vs M headers)", including
# with header => 0, where there is no header and the M came from data row 1 or
# from 'col_names'. A ';'-separated file named .csv.gz, read with header => 0,
# failed with "(2 fields vs 1 headers)", which read as though header => 0 had
# been ignored: the real cause was the default sep ',' that the name chose, so
# that data row 1 was one field and the first row with a comma in its text two.
#
# The message comes from two places, the perl closure in read_table and
# S_fast_row() in LikeR.xs, so every case is read both ways (the private
# _closure => 1 keeps every row in the closure) and the two must agree.
#
# No R or pandas reference applies: the wording is this module's own, and the
# fixtures are written below.
require 5.010;
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

# One gzip member holding $text, as t/read_table.compressed.R.t makes them.
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

# The read's error with the fixture's path as FILE, from the fast path and
# from the closure; is() on the pair says which one differs.
sub errors {
	my ($path, @opt) = @_;
	my @err;
	for my $closure (0, 1) {
		my $e = eval { read_table($path, @opt, $closure ? (_closure => 1) : ()); 1 }
			? '' : $@;
		$e =~ s/\Q$path\E/FILE/g;
		push @err, $e;
	}
	return @err;
}

# ';'-separated, with a comma in the text of the second line: the shape of the
# file this was written for.
my $semi = "a;b;c\nd;e,f;g\n";
my $default_note = "and ',' is only the default sep for this file's name: "
	. "pass 'sep' if its fields are separated by something else";
my @case = (
	[ 'header => 0, ;-separated .csv.gz, default sep',
		fixture('semi.csv.gz', gz($semi)), [ header => 0 ],
		"Alignment error on FILE data row 2 (2 fields vs 1 in data row 1); "
		. "data row 1 has no ',' in it, $default_note.\n" ],
	[ 'header => 1, ;-separated .csv, default sep',
		fixture('semi.csv', $semi), [],
		"Alignment error on FILE data row 1 (2 fields vs 1 headers); "
		. "the header has no ',' in it, $default_note.\n" ],
	[ 'header => 0, ;-separated .csv, sep given',
		fixture('semi2.csv', $semi), [ header => 0, sep => ',' ],
		"Alignment error on FILE data row 2 (2 fields vs 1 in data row 1); "
		. "data row 1 has no ',' in it, so ',' may not be what separates this "
		. "file's fields.\n" ],
	[ 'header => 1, .tsv, default sep',
		fixture('one.tsv', "a b\n1\t2\n"), [],
		"Alignment error on FILE data row 1 (2 fields vs 1 headers); "
		. "the header has no '\\t' in it, and '\\t' is only the default sep for "
		. "this file's name: pass 'sep' if its fields are separated by something "
		. "else.\n" ],
	[ 'header => 0, more fields than data row 1',
		fixture('wide.csv', "1,2\n3,4,5\n"), [ header => 0 ],
		"Alignment error on FILE data row 2 (3 fields vs 2 in data row 1).\n" ],
	[ 'header => 0, fewer fields than data row 1',
		fixture('narrow.csv', "1,2\n3\n"), [ header => 0 ],
		"Alignment error on FILE data row 2 (1 fields vs 2 in data row 1).\n" ],
	# a width of one chosen by the caller says nothing about the sep
	[ "header => 0, 'col_names'",
		fixture('named.csv', "1,2\n"), [ header => 0, col_names => ['x'] ],
		"Alignment error on FILE data row 1 (2 fields vs 1 'col_names').\n" ],
	[ 'header => 1, more than one header',
		fixture('short.csv', "a,b,c\n1,2\n"), [],
		"Alignment error on FILE data row 1 (2 fields vs 3 headers).\n" ],
	# a row with fewer fields than a one-field line is no row at all, so the
	# note can only be wrong where the row has more; the quote's note, which
	# says where the row ran across lines, comes first
	[ 'header => 1, a quote spanning lines as well',
		fixture('span.csv', qq{a\n"x\ny",z\n}), [],
		"Alignment error on FILE data row 1 (2 fields vs 1 headers); a '\"' at "
		. "the start of a field on line 2 opened a quoted field that ran on to "
		. "line 3 (pass quote => '' if '\"' is literal text in this file); the "
		. "header has no ',' in it, $default_note.\n" ],
);
for my $c (@case) {
	my ($tag, $path, $opt, $want) = @$c;
	my ($fast, $closed) = errors($path, @$opt);
	is $fast,   $want, "$tag: the fast path's message";
	is $closed, $want, "$tag: the closure's message";
}

# A regex sep is named as it stringifies, which differs between perls.
{
	my $re = qr/\s+/;
	my ($fast, $closed) = errors(fixture('ws.txt', "ab\nc d\n"),
		header => 0, sep => $re);
	my $want = "Alignment error on FILE data row 2 (2 fields vs 1 in data row 1); "
		. "data row 1 has no match for the sep regex $re, so it may not be what "
		. "separates this file's fields.\n";
	is $fast,   $want, 'a regex sep: the fast path names the regex';
	is $closed, $want, 'a regex sep: the closure names it the same way';
}

# The note's advice works: the same file read with its own sep.
is_deeply read_table(fixture('semi3.csv.gz', gz($semi)), header => 0, sep => ';'),
	[ { V1 => 'a', V2 => 'b',   V3 => 'c' },
	  { V1 => 'd', V2 => 'e,f', V3 => 'g' } ],
	'the ;-separated .csv.gz reads with sep => \';\'';

done_testing();
