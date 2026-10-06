#!/usr/bin/env perl
# Regenerates the expected rows in t/read_table.sep_unicode.t.
#
#   perl t/read_table.sep_unicode.pl
#
# The reference is perl's own split() on the text as characters: a line that
# is valid UTF-8 is decoded, split with the sep regex, and each piece encoded
# back to the bytes the file held; a line that is not (Latin-1) is split as
# the bytes it is. It splits with m//g rather than split(), because perl
# compiles split /\s+/ to a fast path (RXf_WHITE) that tests each byte with
# isSPACE() and so ignores /u: split /\s+/u, "x\xa0y" is one field, though
# "x\xa0y" =~ /\s+/u matches (perl 5.44.0). That is what read_table promises for a sep regex that reads
# characters (/u, /a, /aa; S_rx_reads_chars() in LikeR.xs), and it needs
# nothing but perl, so it cannot share a bug with the parser. qr/\s+/ also
# drops the empty fields leading and trailing blanks would make, as read_table
# reads it. The test never runs this: paste what it prints over its @case.
# @pat and @input below are the test's own, copied: change them together.
require 5.014;
use strict;
use warnings;
use Encode ();
use Data::Dumper;
$Data::Dumper::Useqq = 1; $Data::Dumper::Indent = 0; $Data::Dumper::Terse = 1;
my @pat = ('qr/\s+/u', 'qr/\h+/u', 'qr/[[:space:]]+/u', 'qr/\p{Zs}+/', 'qr/\h+/a');
# [tag, the data line's bytes]; every file is "h1 h2\n" and then this line
my @input = (
	['voila',               "voil\xc3\xa0 x"],
	['Cyrillic Er',         "\xd0\xa0 x"],
	['NEL inside a char',   "\xc5\x85 x"],
	['quoted',              "\"voil\xc3\xa0 x\" y"],
	['Latin-1 0xA0',        "x\xa0y"],
	['U+00A0 separator',    "x\xc2\xa0y"],
	['U+2003 separator',    "x\xe2\x80\x83y"],
	['U+0085 separator',    "x\xc2\x85y"],
	['leading U+00A0',      "\xc2\xa0x y"],
);
# split($rx, $s, -1), by matching: every match of a non-empty separator ends a field
sub cut {
	my ($rx, $s) = @_;
	my ($from, @f) = (0);
	while ($s =~ /$rx/g) {
		push @f, substr($s, $from, $-[0] - $from);
		$from = $+[0];
	}
	return (@f, substr($s, $from));
}
for my $p (@pat) {
	my $rx = eval $p or die $@;
	my $ws = $p eq 'qr/\s+/u';
	for my $c (@input) {
		my ($tag, $bytes) = @$c;
		my @f;
		my $text = $bytes;
		my $utf8 = $text =~ /[\x80-\xff]/ && utf8::decode($text);
		my $line = $utf8 ? $text : $bytes;
		if ($line =~ /\A"(.*)"(.*)\z/s) {	# the one quoted case: a quoted first field
			my ($q, $rest) = ($1, $2);
			@f = ($q, grep { length } cut($rx, $rest));
		} else {
			@f = cut($rx, $line);
			if ($ws) {
				shift @f while @f && $f[0] eq '';
				pop @f while @f && $f[-1] eq '';
			}
		}
		@f = map { my $s = $_; utf8::encode($s) if $utf8; $s } @f;
		my $want = @f == 2 ? [['h1', 'h2'], [@f]] : undef;
		my $err  = @f == 2 ? '' : "Alignment error on FILE data row 1 (" . scalar(@f) . " fields vs 2 headers).\n";
		print "\t[", join(', ', map { Dumper($_) } $p, $tag, $want, $err), "],\n";
	}
}
