#!/usr/bin/env perl
# read_table's sep => qr/\s+/, split in C.
#
# Up to 0.3213 every field of a whitespace-separated file was found by a
# pregexec() of the sep regex; a 300,000 x 10 file took 0.35 s to read as an
# aoa, against 0.19 s with sep => ' '. qr/\s+/ is now split by a byte scan in
# _parse_csv_file() (the ws_c branch in LikeR.xs), whenever the engine's \s is
# isSPACE() byte for byte -- the default rules and /a, not /u or /l
# (S_rx_space_is_isspace()). That scan has to give the regex path's answer in
# every case, and this pins it: leading and trailing blanks, runs of mixed
# blanks, \v, blank and blank-looking lines, quotes opening, closing, spanning
# lines and switched off, CR and CRLF line ends and a CR inside a line, 0x85
# and 0xA0 (blanks to /u, text here), and UTF-8.
#
# Provenance: every expected row is what the regex path returned for the
# input, frozen. They were printed by t/read_table.ws_sep.pl, which reads each
# input with qr/\s+/l -- a regex read_table still hands to the engine -- under
# LC_ALL=C, where /l's \s is [\t\n\v\f\r ], the default \s from perl 5.18 on.
# Re-run it with `LC_ALL=C perl -Iblib/lib -Iblib/arch t/read_table.ws_sep.pl`
# from the distribution root (on perl 5.18 or later) and paste its output over
# @case. On 0.3213, before the C path existed, the same script with qr/\s+/
# printed the same table byte for byte; and 1,500 random files of blanks
# (\v among them), quotes, CRs and high bytes, each read eight ways, gave the
# same rows, errors and warnings from the 0.3213 build and this one, on perl
# 5.44.0 and on 5.10.1.
# No R or Python reference applies: R's sep = "" and pandas' sep=r"\s+" differ
# from it and from each other on CR and on quotes, and t/read_table.regex_sep.t
# and t/read_table.header_quote.R.pandas.t already pin the cases they share.

require 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;
use File::Temp ();
use File::Spec;
use Stats::LikeR qw(read_table);

my $dir = File::Temp::tempdir(CLEANUP => 1);
my $n = 0;
sub fixture {
	my ($text) = @_;
	my $path = File::Spec->catfile($dir, 'w' . $n++ . '.txt');
	open my $fh, '>:raw', $path or die "cannot write $path: $!";
	print {$fh} $text;
	close $fh or die "cannot write $path: $!";
	return $path;
}

my @input = (
	['leading and trailing blanks', "  a  b  \n 1\t2\t\n", []],
	['runs of mixed blanks',        "a \t b\n1\f\f2\n", []],
	['vertical tab',                "a\x0bb\n1 2\n", []],
	['blank lines',                 "a b\n\n   \n\t\n1 2\n", []],
	['a line of one form feed',     "a\n\f\n1\n", []],
	['no final newline',            "a b\n1 2", []],
	['comment lines',               "# note\na b\n# more\n1 2\n", []],
	['quoted fields',               qq{"x y" z\n"a b" "c"\n}, []],
	['a quote mid-field',           qq{h1 h2\nab"c d" e\n}, []],
	['a quote spanning lines',      qq{h1 h2\n"x\ny" z\n}, []],
	['a closing quote then text',   qq{h1 h2\n"x"y z\n}, []],
	['an empty quoted field',       qq{h1 h2\n"" z\n}, []],
	['quoting off',                 qq{"x y" z\n"a b" "c"\n}, [quote => '']],
	['CRLF',                        "a b\r\n1 2\r\n", []],
	['blanks before CRLF',          "a b \r\n1 2\t\r\n", []],
	['a stray CR',                  "a\rb c\n1 2\n", []],
	['a CR after a blank',          "a \rb c\n1 2\n", []],
	['a CR before a blank',         "a\r b c\n1 2 3\n", []],
	['bare CR line ends',           "a b\r1 2\r", []],
	['0xA0 and 0x85 are text',      "a\xa0b c\x85d\n1 2\n", []],
	['UTF-8 text',                  "a b\nvoil\xc3\xa0 \xd0\xa0\n", []],
	['no header',                   " 1 2 \n3\t4\n", [header => 0]],
	['ragged',                      "a b\n1 2 3\n", []],
);

# [tag, the aoa read_table returns, its error with the path as FILE, its warnings], as
# t/read_table.ws_sep.pl printed them
my @case = (
	["leading and trailing blanks", [["a","b"],[1,2]], "", []],
	["runs of mixed blanks", [["a","b"],[1,2]], "", []],
	["vertical tab", [["a","b"],[1,2]], "", []],
	["blank lines", [["a","b"],[1,2]], "", []],
	["a line of one form feed", [["a"],[undef],[1]], "", []],
	["no final newline", [["a","b"],[1,2]], "", []],
	["comment lines", [["a","b"],[1,2]], "", []],
	["quoted fields", [["x y","z"],["a b","c"]], "", []],
	["a quote mid-field", [["h1","h2"],["abc d","e"]], "", []],
	["a quote spanning lines", [["h1","h2"],["x\ny","z"]], "", []],
	["a closing quote then text", [["h1","h2"],["xy","z"]], "", []],
	["an empty quoted field", [["h1","h2"],[undef,"z"]], "", []],
	["quoting off", [["\"x","y\"","z"],["\"a","b\"","\"c\""]], "", []],
	["CRLF", [["a","b"],[1,2]], "", []],
	["blanks before CRLF", [["a","b"],[1,2]], "", []],
	["a stray CR", [["ab","c"],[1,2]], "", []],
	["a CR after a blank", undef, "Alignment error on FILE data row 1 (2 fields vs 3 headers).\n", []],
	["a CR before a blank", [["a","b","c"],[1,2,3]], "", []],
	["bare CR line ends", [["a","b"],[1,2]], "", []],
	["0xA0 and 0x85 are text", [["a\240b","c\205d"],[1,2]], "", []],
	["UTF-8 text", [["a","b"],["voil\303\240","\320\240"]], "", []],
	["no header", [["V1","V2"],[1,2],[3,4]], "", []],
	["ragged", undef, "Alignment error on FILE data row 1 (3 fields vs 2 headers).\n", []],
);
# \v is \s, and isSPACE(), only from perl 5.18 on; before that it is text
# to both, and "a\x0bb" is one column.
if ($] < 5.018) {
	$_->[1] = undef, $_->[2] = "Alignment error on FILE data row 1 (2 fields vs 1 headers).\n"
		for grep { $_->[0] eq 'vertical tab' } @case;
}

is(scalar @case, scalar @input, 'one expected answer per input');
my @rx = (['qr/\s+/', qr/\s+/]);
push @rx, ['qr/\s+/a', eval 'qr/\s+/a'] if $] >= 5.014;	# /a is 5.14's; a string eval so 5.10 can parse the file
for my $i (0 .. $#input) {
	my ($tag, $text, $opt) = @{ $input[$i] };
	my (undef, $want, $want_err, $want_warn) = @{ $case[$i] };
	my $path = fixture($text);
	for my $r (@rx) {
		my @w;
		local $SIG{__WARN__} = sub { push @w, $_[0] };
		my $got = eval { read_table($path, @$opt, sep => $r->[1], output_type => 'aoa') };
		(my $err = $@) =~ s/\Q$path\E/FILE/g;
		s/\Q$path\E/FILE/g for @w;
		is_deeply($got, $want, "$tag, $r->[0]: the rows");
		is($err, $want_err, "$tag, $r->[0]: the error");
		is_deeply(\@w, $want_warn, "$tag, $r->[0]: the warnings");
	}
}

done_testing();
