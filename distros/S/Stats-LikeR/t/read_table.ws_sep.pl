#!/usr/bin/env perl
# Regenerates the expected rows in t/read_table.ws_sep.t.
#
#   LC_ALL=C perl -Iblib/lib -Iblib/arch t/read_table.ws_sep.pl
#
# read_table splits sep => qr/\s+/ in C, and every other sep regex with perl's
# regex engine.  This reads each input of the test with qr/\s+/l instead,
# which read_table still hands to the engine (S_rx_space_is_isspace() in
# LikeR.xs), so the table it prints is the regex path's answer -- the one the
# C path has to give.  Under LC_ALL=C, /l's \s is the C library's isspace(),
# [\t\n\v\f\r ], which is the default \s from perl 5.18 on; run it on 5.18 or
# later.  Before 5.18 the default \s lacks \v, and the test keys that one case
# on $].  The test never runs this: paste what it prints over its @case table.
# @input below is the test's own @input, copied: change the two together.
require 5.018;
use strict;
use warnings;
use Data::Dumper;
use File::Temp ();
use File::Spec;
use Stats::LikeR qw(read_table);
$Data::Dumper::Useqq = 1; $Data::Dumper::Indent = 0; $Data::Dumper::Sortkeys = 1; $Data::Dumper::Terse = 1;
my $dir = File::Temp::tempdir(CLEANUP => 1);
my $n = 0;
# [tag, file text, read_table options]: each shape the C splitter decides
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
my $rx = qr/\s+/l;
for my $c (@input) {
	my ($tag, $text, $opt) = @$c;
	my $path = File::Spec->catfile($dir, 'w' . $n++ . '.txt');
	open my $fh, '>:raw', $path or die "cannot write $path: $!";
	print {$fh} $text;
	close $fh or die "cannot write $path: $!";
	my @w;
	local $SIG{__WARN__} = sub { push @w, $_[0] };
	my $r = eval { read_table($path, @$opt, sep => $rx, output_type => 'aoa') };
	(my $err = $@) =~ s/\Q$path\E/FILE/g;
	s/\Q$path\E/FILE/g for @w;
	print "\t[", join(', ', map { Dumper($_) } $tag, $r, $err, \@w), "],\n";
}
