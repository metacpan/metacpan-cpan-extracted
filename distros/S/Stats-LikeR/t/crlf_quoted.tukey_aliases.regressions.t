#!/usr/bin/env perl
#
# Two defects in 0.3416, each pinned so that it stays fixed.
#
# read_table() cut a line's end off before parsing it, and a line that ended
# inside a quote got a bare "\n" back, so a CR LF inside a quoted field came back
# as LF alone: "a\r\nb" read as "a\nb", and write_table() -> read_table() did not
# round-trip it. A field now keeps the bytes the file holds.
#
# On MSWin32, 0.3417 still lost that CR LF in a plain file, and write_table()
# doubled the CR, because both opened their file in text mode; see below.
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
#--------
# MSWin32: 0.3417 opened the file text-mode on both sides, so :crlf turned a
# quoted "1\r\n2" into "1\r\r\n2" on disk and a plain file's quoted CR LF into
# LF on the way back in, while a .gz kept it. Both handles are binary now, and
# only the row end is the platform's ("\r\n" where a '>' open gets :crlf).
#--------
{
	my $nl = do {
		open my $fh, '>', "$dir/nl.probe" or die "cannot write a probe: $!\n";
		my $crlf = grep { $_ eq 'crlf' } PerlIO::get_layers($fh);
		close $fh;
		$crlf ? "\r\n" : "\n";
	};
	my $f = "$dir/raw.csv";
	write_table([['x', "1\n2"], ['y', "3\r\n4"]], $f, col_names => ['id', 'v'],
		quiet => 1);
	open my $fh, '<:raw', $f or die "$f: $!";
	my $bytes = do { local $/; <$fh> };
	close $fh;
	is($bytes, "id,v$nl" . "x,\"1\n2\"$nl" . "y,\"3\r\n4\"$nl",
		'write_table writes a field\'s bytes as they are, and the row end as the platform\'s');
	my $got = read_table($f, output_type => 'aoa', colClasses => 'character');
	is_deeply([ map { $_->[1] } @$got[1, 2] ], [ "1\n2", "3\r\n4" ],
		'... and read_table reads them back unchanged');
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
