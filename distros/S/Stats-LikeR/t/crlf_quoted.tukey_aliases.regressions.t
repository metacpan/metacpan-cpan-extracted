#!/usr/bin/env perl
#
# Two defects in 0.3416, each pinned so that it stays fixed.
#
# read_table() cut a line's end off before parsing it, and a line that ended
# inside a quote got a bare "\n" back, so a CR LF inside a quoted field came back
# as LF alone: "a\r\nb" read as "a\nb", and write_table() -> read_table() did not
# round-trip it. A field now keeps the bytes the file holds.
#
# ptukey() and qtukey() took only lower_tail and log_p, where pt() and the rest
# of the distribution functions also take lower and log, so ptukey(..., lower =>
# 0) croaked with "unknown argument".
#
# Provenance: pandas 3.0.4, pd.read_csv(f, dtype=str, keep_default_na=False) on
# each "c\n\"<s>\"\n" file below, reads every <s> back unchanged. R 4.6.1's
# read.csv() is not the reference here: it turns each CR inside quotes into an
# LF. The ptukey/qtukey cases compare the aliases with the long names, so they
# need no reference value.
require 5.010;
use strict;
use warnings FATAL => 'all';
use File::Temp;
use Stats::LikeR;
use Test::More;
use Test::LeakTrace 'no_leaks_ok';

my $dir = File::Temp::tempdir(CLEANUP => 1);
#--------
# read_table: CR LF inside a quoted field is data, not a line ending
#--------
foreach my $s ("a\r\nb", "\r\n", "x\r\n\r\ny", "a\rb", "a\nb") {
	my $f = "$dir/crlf.csv";
	open my $fh, '>:raw', $f or die "$f: $!";
	print {$fh} "c\n\"$s\"\n";
	close $fh;
	my $got = read_table($f, output_type => 'aoa');
	(my $name = $s) =~ s/\r/\\r/g;
	$name =~ s/\n/\\n/g;
	is($got->[1][0], $s, "read_table keeps \"$name\" inside quotes");
}
{
	my $f = "$dir/rt.csv";
	write_table([['x', "1\r\n2"]], $f, col_names => ['id', 'v'], quiet => 1);
	my $got = read_table($f, output_type => 'aoa', colClasses => 'character');
	is($got->[1][1], "1\r\n2", 'write_table -> read_table round-trips CR LF');
}
no_leaks_ok {
	read_table("$dir/crlf.csv", output_type => 'aoa')
} 'read_table(): no memory leaks' unless $INC{'Devel/Cover.pm'};
#--------
# ptukey / qtukey: lower and log aliases, as pt() has
#--------
is(eval { ptukey(3.5, 3, 12, lower => 0) },
	ptukey(3.5, 3, 12, lower_tail => 0), 'ptukey accepts lower');
is(eval { ptukey(3.5, 3, 12, log => 1) },
	ptukey(3.5, 3, 12, log_p => 1), 'ptukey accepts log');
is(eval { qtukey(0.05, 3, 12, lower => 0) },
	qtukey(0.05, 3, 12, lower_tail => 0), 'qtukey accepts lower');
is(eval { qtukey(-3, 3, 12, log => 1) },
	qtukey(-3, 3, 12, log_p => 1), 'qtukey accepts log');
done_testing();
