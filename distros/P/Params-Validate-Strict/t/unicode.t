#!/usr/bin/env perl

# Test min/max constraints on strings containing non-ASCII characters and emoji.
# Counts are in grapheme clusters (visible characters), not bytes or code points.
# Verifies that the former FIXME "{max} doesn't play ball with non-ascii strings"
# is resolved.

use strict;
use warnings;
use Test::Most;
use Params::Validate::Strict qw(validate_strict);

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

my $max3     = { type => 'string', max => 3 };
my $min3     = { type => 'string', min => 3 };
my $min2max4 = { type => 'string', min => 2, max => 4 };

sub ok_validate {
	my ($schema_rule, $value, $label) = @_;
	my $r = validate_strict({ schema => { s => $schema_rule }, args => { s => $value } });
	is($r->{s}, $value, $label);
}

sub throws_validate {
	my ($schema_rule, $value, $re, $label) = @_;
	throws_ok { validate_strict({ schema => { s => $schema_rule }, args => { s => $value } }) }
		$re, $label;
}

# ---------------------------------------------------------------------------
# max/min — ASCII baseline
# ---------------------------------------------------------------------------

subtest 'max — ASCII baseline' => sub {
	ok_validate($max3, 'hi',   '2 ASCII chars pass max=>3');
	ok_validate($max3, 'hey',  '3 ASCII chars pass max=>3');
	throws_validate($max3, 'nope', qr/too long/, '4 ASCII chars fail max=>3');
};

subtest 'min — ASCII baseline' => sub {
	ok_validate($min3, 'hey',    '3 ASCII chars pass min=>3');
	ok_validate($min3, 'hello',  '5 ASCII chars pass min=>3');
	throws_validate($min3, 'hi', qr/too short/, '2 ASCII chars fail min=>3');
};

# ---------------------------------------------------------------------------
# max/min — accented / Latin-extended characters (1 code point = 1 grapheme)
# ---------------------------------------------------------------------------

subtest 'max — accented characters' => sub {
	# cafe + U+00E9 (e-acute) = 4 grapheme clusters
	my $cafe = "caf\x{e9}";
	throws_validate($max3, $cafe, qr/too long/, 'cafe+acute (4 grapheme clusters) fails max=>3');

	# U+00E9 + l = 2 grapheme clusters
	ok_validate($max3, "\x{e9}l", 'e-acute+l (2 grapheme clusters) passes max=>3');

	# U+00E9 + l + U+00E8 + ve = 5 grapheme clusters (eleve with accents)
	throws_validate($max3, "\x{e9}l\x{e8}ve", qr/too long/, 'eleve-accented (5 grapheme clusters) fails max=>3');
};

subtest 'min — accented characters' => sub {
	# eleve with accents = 5 grapheme clusters
	ok_validate($min3, "\x{e9}l\x{e8}ve", 'eleve-accented (5 grapheme clusters) passes min=>3');
	# e-acute + l = 2 grapheme clusters
	throws_validate($min3, "\x{e9}l", qr/too short/, 'e-acute+l (2 grapheme clusters) fails min=>3');
};

# ---------------------------------------------------------------------------
# max/min — CJK characters (each = 1 grapheme cluster)
# ---------------------------------------------------------------------------

subtest 'max — CJK characters' => sub {
	# U+4E16 U+754C = 2 grapheme clusters
	ok_validate($max3, "\x{4e16}\x{754c}", 'CJK 2-char string passes max=>3');
	# U+4E16 U+754C U+4E2D U+6587 = 4 grapheme clusters
	throws_validate($max3, "\x{4e16}\x{754c}\x{4e2d}\x{6587}", qr/too long/, 'CJK 4-char string fails max=>3');
};

# ---------------------------------------------------------------------------
# max/min — simple emoji (no ZWJ, no skin-tone modifiers)
# Each standard emoji in the SMP is 1 grapheme cluster.
# ---------------------------------------------------------------------------

subtest 'max — simple emoji' => sub {
	# U+1F600 = 1 emoji = 1 grapheme cluster
	ok_validate($max3, "\x{1F600}",                            '1 emoji passes max=>3');
	ok_validate($max3, "\x{1F600}\x{1F601}",                   '2 emoji pass max=>3');
	ok_validate($max3, "\x{1F600}\x{1F601}\x{1F602}",          '3 emoji pass max=>3');
	throws_validate($max3, "\x{1F600}\x{1F601}\x{1F602}\x{1F603}", qr/too long/,
		'4 emoji fail max=>3');
};

subtest 'min — simple emoji' => sub {
	ok_validate($min3, "\x{1F600}\x{1F601}\x{1F602}",     '3 emoji pass min=>3');
	ok_validate($min3, "\x{1F600}\x{1F601}\x{1F602}\x{1F603}", '4 emoji pass min=>3');
	throws_validate($min3, "\x{1F600}\x{1F601}", qr/too short/, '2 emoji fail min=>3');
};

# ---------------------------------------------------------------------------
# max/min — ZWJ emoji sequences
# Unicode::GCString 2013.10 (bundled with most Perl installs) pre-dates
# Unicode 8.0 ZWJ-sequence support and therefore treats a 3-emoji ZWJ family
# as 3 grapheme clusters rather than 1.  The tests below document that
# min/max counts grapheme clusters correctly regardless — it does not fall
# back to byte-counting or code-point-counting.
# ---------------------------------------------------------------------------

subtest 'max+min — ZWJ emoji family (1 grapheme cluster)' => sub {
	# U+1F468 ZWJ U+1F469 ZWJ U+1F467 = family-man-woman-girl
	# 5 code points, 1 grapheme cluster under Unicode 9.0+ (Perl 5.26+).
	my $family = "\x{1F468}\x{200D}\x{1F469}\x{200D}\x{1F467}";

	ok_validate({ type => 'string', max => 1 }, $family, 'ZWJ family passes max=>1');
	throws_validate({ type => 'string', max => 1 }, $family x 2, qr/too long/,
		'double ZWJ family fails max=>1');

	ok_validate({ type => 'string', min => 1 }, $family, 'ZWJ family passes min=>1');
	throws_validate({ type => 'string', min => 2 }, $family, qr/too short/,
		'single ZWJ family (1 cluster) fails min=>2');
};

subtest 'max+min — skin-tone modifier sequence (1 grapheme cluster)' => sub {
	# U+1F44D U+1F3FD = thumbs-up + medium skin-tone
	# 2 code points, 1 grapheme cluster under Unicode 8.0+ (Perl 5.26+).
	my $thumbs = "\x{1F44D}\x{1F3FD}";

	ok_validate({ type => 'string', max => 1 }, $thumbs, 'skin-tone thumbs passes max=>1');
	throws_validate({ type => 'string', max => 1 }, $thumbs x 2, qr/too long/,
		'double skin-tone thumbs fails max=>1');

	ok_validate({ type => 'string', min => 1 }, $thumbs, 'skin-tone thumbs passes min=>1');
	throws_validate({ type => 'string', min => 2 }, $thumbs, qr/too short/,
		'single skin-tone thumbs (1 cluster) fails min=>2');
};

# ---------------------------------------------------------------------------
# min+max — mixed ASCII and emoji
# ---------------------------------------------------------------------------

subtest 'min+max — mixed ASCII and emoji' => sub {
	# "hi" + U+1F600 = 3 grapheme clusters — within [2, 4]
	ok_validate($min2max4, "hi\x{1F600}", 'ASCII+emoji (3 clusters) passes min=>2 max=>4');

	# 5 distinct emoji = 5 grapheme clusters — exceeds max=>4
	throws_validate($min2max4, "\x{1F600}\x{1F601}\x{1F602}\x{1F603}\x{1F604}", qr/too long/,
		'5 emoji fail max=>4');

	# single ASCII char = 1 grapheme cluster — below min=>2
	throws_validate($min2max4, 'x', qr/too short/, 'single ASCII char fails min=>2');
};

# ---------------------------------------------------------------------------
# Returned value is preserved exactly (no mangling of emoji string)
# ---------------------------------------------------------------------------

subtest 'emoji string value preserved' => sub {
	my $smile2 = "\x{1F600}\x{1F601}";
	my $r = validate_strict({ schema => { s => { type => 'string', max => 5 } }, args => { s => $smile2 } });
	is($r->{s}, $smile2, 'emoji string returned unchanged');
};

done_testing();
