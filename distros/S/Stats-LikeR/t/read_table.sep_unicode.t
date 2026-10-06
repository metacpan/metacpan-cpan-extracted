#!/usr/bin/env perl
# read_table: a sep regex that reads characters meets a UTF-8 line as UTF-8.
#
# Up to 0.3213 every non-UTF-8 sep regex was matched against the line's bytes.
# A pattern under Unicode rules -- /u, which `use v5.12` and later or `use
# feature 'unicode_strings'` put on every qr// in their scope, and which \p{}
# and \N{U+...} imply -- takes the bytes 0x85 and 0xA0 for NEL and no-break
# space, and /a and /aa do for \h and \p{}. Those are the trailing bytes of many
# UTF-8 characters, so qr/\s+/u cut "voila" with a grave a (C3 A0) into
# "voil\xC3" and a separator, and Cyrillic Er (D0 A0) likewise; and it could
# never match a U+2003 between fields. Such a pattern (S_rx_reads_chars() in
# LikeR.xs) is now shown a line as UTF-8 when the line is valid UTF-8 and not
# all ASCII. A line that is not valid UTF-8 is matched as bytes as before, so
# a Latin-1 0xA0 is still a no-break space to /u. The cells are the file's
# bytes either way. A /d pattern is left as bytes: qr/\xe2\x80\x94/ there means
# an em dash's three bytes, and still finds them.
#
# Provenance: the expected rows are perl's own reading of the same text as
# characters -- each line decoded when it is valid UTF-8, cut at every match
# of the sep regex, and each piece encoded back to the file's bytes -- printed
# by t/read_table.sep_unicode.pl (re-run it with
# `perl t/read_table.sep_unicode.pl` and paste its output over @case; it needs
# nothing but perl 5.14). Python 3.14's re.split(r'\s+', ...) on the decoded
# text agrees for every qr/\s+/u case: 'voil\xe0 x' and 'Р x' are not cut
# inside a character, and U+00A0, U+2003 and U+0085 separate. R and pandas
# offer no reference for /u as such: R's sep = "" and pandas' sep=r"\s+" split
# on ASCII blanks only, which is what read_table's plain qr/\s+/ does
# (t/read_table.ws_sep.t).

require 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;
use File::Temp ();
use File::Spec;
use Stats::LikeR qw(read_table);

plan skip_all => 'the /u, /a and /aa modifiers are perl 5.14\'s' if $] < 5.014;

my $dir = File::Temp::tempdir(CLEANUP => 1);
my $n = 0;
sub fixture {
	my ($text) = @_;
	my $path = File::Spec->catfile($dir, 'u' . $n++ . '.txt');
	open my $fh, '>:raw', $path or die "cannot write $path: $!";
	print {$fh} $text;
	close $fh or die "cannot write $path: $!";
	return $path;
}

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

# [pattern, input tag, the aoa read_table returns, its error with the path as FILE],
# as t/read_table.sep_unicode.pl printed them
my @case = (
	["qr/\\s+/u", "voila", [["h1","h2"],["voil\303\240","x"]], ""],
	["qr/\\s+/u", "Cyrillic Er", [["h1","h2"],["\320\240","x"]], ""],
	["qr/\\s+/u", "NEL inside a char", [["h1","h2"],["\305\205","x"]], ""],
	["qr/\\s+/u", "quoted", [["h1","h2"],["voil\303\240 x","y"]], ""],
	["qr/\\s+/u", "Latin-1 0xA0", [["h1","h2"],["x","y"]], ""],
	["qr/\\s+/u", "U+00A0 separator", [["h1","h2"],["x","y"]], ""],
	["qr/\\s+/u", "U+2003 separator", [["h1","h2"],["x","y"]], ""],
	["qr/\\s+/u", "U+0085 separator", [["h1","h2"],["x","y"]], ""],
	["qr/\\s+/u", "leading U+00A0", [["h1","h2"],["x","y"]], ""],
	["qr/\\h+/u", "voila", [["h1","h2"],["voil\303\240","x"]], ""],
	["qr/\\h+/u", "Cyrillic Er", [["h1","h2"],["\320\240","x"]], ""],
	["qr/\\h+/u", "NEL inside a char", [["h1","h2"],["\305\205","x"]], ""],
	["qr/\\h+/u", "quoted", [["h1","h2"],["voil\303\240 x","y"]], ""],
	["qr/\\h+/u", "Latin-1 0xA0", [["h1","h2"],["x","y"]], ""],
	["qr/\\h+/u", "U+00A0 separator", [["h1","h2"],["x","y"]], ""],
	["qr/\\h+/u", "U+2003 separator", [["h1","h2"],["x","y"]], ""],
	["qr/\\h+/u", "U+0085 separator", undef, "Alignment error on FILE data row 1 (1 fields vs 2 headers).\n"],
	["qr/\\h+/u", "leading U+00A0", undef, "Alignment error on FILE data row 1 (3 fields vs 2 headers).\n"],
	["qr/[[:space:]]+/u", "voila", [["h1","h2"],["voil\303\240","x"]], ""],
	["qr/[[:space:]]+/u", "Cyrillic Er", [["h1","h2"],["\320\240","x"]], ""],
	["qr/[[:space:]]+/u", "NEL inside a char", [["h1","h2"],["\305\205","x"]], ""],
	["qr/[[:space:]]+/u", "quoted", [["h1","h2"],["voil\303\240 x","y"]], ""],
	["qr/[[:space:]]+/u", "Latin-1 0xA0", [["h1","h2"],["x","y"]], ""],
	["qr/[[:space:]]+/u", "U+00A0 separator", [["h1","h2"],["x","y"]], ""],
	["qr/[[:space:]]+/u", "U+2003 separator", [["h1","h2"],["x","y"]], ""],
	["qr/[[:space:]]+/u", "U+0085 separator", [["h1","h2"],["x","y"]], ""],
	["qr/[[:space:]]+/u", "leading U+00A0", undef, "Alignment error on FILE data row 1 (3 fields vs 2 headers).\n"],
	["qr/\\p{Zs}+/", "voila", [["h1","h2"],["voil\303\240","x"]], ""],
	["qr/\\p{Zs}+/", "Cyrillic Er", [["h1","h2"],["\320\240","x"]], ""],
	["qr/\\p{Zs}+/", "NEL inside a char", [["h1","h2"],["\305\205","x"]], ""],
	["qr/\\p{Zs}+/", "quoted", [["h1","h2"],["voil\303\240 x","y"]], ""],
	["qr/\\p{Zs}+/", "Latin-1 0xA0", [["h1","h2"],["x","y"]], ""],
	["qr/\\p{Zs}+/", "U+00A0 separator", [["h1","h2"],["x","y"]], ""],
	["qr/\\p{Zs}+/", "U+2003 separator", [["h1","h2"],["x","y"]], ""],
	["qr/\\p{Zs}+/", "U+0085 separator", undef, "Alignment error on FILE data row 1 (1 fields vs 2 headers).\n"],
	["qr/\\p{Zs}+/", "leading U+00A0", undef, "Alignment error on FILE data row 1 (3 fields vs 2 headers).\n"],
	["qr/\\h+/a", "voila", [["h1","h2"],["voil\303\240","x"]], ""],
	["qr/\\h+/a", "Cyrillic Er", [["h1","h2"],["\320\240","x"]], ""],
	["qr/\\h+/a", "NEL inside a char", [["h1","h2"],["\305\205","x"]], ""],
	["qr/\\h+/a", "quoted", [["h1","h2"],["voil\303\240 x","y"]], ""],
	["qr/\\h+/a", "Latin-1 0xA0", [["h1","h2"],["x","y"]], ""],
	["qr/\\h+/a", "U+00A0 separator", [["h1","h2"],["x","y"]], ""],
	["qr/\\h+/a", "U+2003 separator", [["h1","h2"],["x","y"]], ""],
	["qr/\\h+/a", "U+0085 separator", undef, "Alignment error on FILE data row 1 (1 fields vs 2 headers).\n"],
	["qr/\\h+/a", "leading U+00A0", undef, "Alignment error on FILE data row 1 (3 fields vs 2 headers).\n"],
);

is(scalar @case, @pat * @input, 'one expected answer per pattern and input');
my %rx = map { $_ => (eval $_ or die $@) } @pat;	# string evals: 5.10 cannot parse /u
my %text = map { $_->[0] => "h1 h2\n$_->[1]\n" } @input;
for my $c (@case) {
	my ($p, $tag, $want, $want_err) = @$c;
	my $path = fixture($text{$tag});
	my $got = eval { read_table($path, sep => $rx{$p}, output_type => 'aoa') };
	(my $err = $@) =~ s/\Q$path\E/FILE/g;
	is_deeply($got, $want, "$p, $tag: the rows");
	is($err, $want_err, "$p, $tag: the error");
}

# --- what stays bytes ----------------------------------------------------------------
{
	my $f = fixture("a\xe2\x80\x94b\nx\xe2\x80\x94y\n");
	is_deeply(read_table($f, sep => qr/\xe2\x80\x94/, output_type => 'aoa'),
	          [['a', 'b'], ['x', 'y']], 'a /d pattern written as UTF-8 bytes still finds them');
	my $u = eval 'qr/\s+/u';
	my $lat = fixture("h1 h2\nx \xe9\n");	# Latin-1 e-acute: not valid UTF-8
	is_deeply(read_table($lat, sep => $u, output_type => 'aoa'), [['h1', 'h2'], ['x', "\xe9"]],
	          'a Latin-1 line under /u is matched as the bytes it is');
	my $cells = read_table(fixture("h1 h2\nvoil\xc3\xa0 x\n"), sep => $u, output_type => 'aoa');
	ok(!utf8::is_utf8($cells->[1][0]), 'a cell of a line matched as UTF-8 is still bytes, without the flag');
}

# --- no leaks ------------------------------------------------------------------------
SKIP: {
	skip 'Test::LeakTrace is not installed', 1 unless eval { require Test::LeakTrace; 1 };
	skip 'under Devel::Cover', 1 if $INC{'Devel/Cover.pm'};
	my $u = eval 'qr/\s+/u';	# compiled outside the block: 5.10.0's pp_qr() leaks an SV per qr//
	my $f = fixture("h1 h2\nvoil\xc3\xa0 x\n\xc2\xa0x\xe2\x80\x83y\nx\xa0y\n");
	Test::LeakTrace::no_leaks_ok(sub { read_table($f, sep => $u, output_type => 'aoh') },
		'a /u read of UTF-8 and Latin-1 lines leaks nothing');
}

done_testing();
