#!/usr/bin/env perl
# read_table does not depend on the caller's $/.
#
# _parse_csv_file() reads with sv_gets(), which splits on PL_rs -- the current
# value of $/ -- rather than on newlines. Until 0.319 a `local $/;` anywhere up
# the call stack, the everyday idiom for slurping some other file, made the
# whole CSV one "line": read_table returned [] and said nothing. A record
# length ($/ = \N) cut rows at N bytes and died with a misleading alignment
# error, and paragraph mode ($/ = '') merged rows. The perl side's peek at the
# first line, which recovers a commented-out header, read with $/ as well.
#
# There is no R or pandas counterpart: $/ is perl's. What is pinned is that
# every setting of it reads the same table as the default does, on both of
# read_table's paths, and that a filter -- user code, run while the parser is
# mid-file -- still sees the caller's $/ and not the parser's.
require 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;
use File::Temp ();
use File::Spec ();
use Stats::LikeR qw(read_table);

my $dir = File::Temp::tempdir(CLEANUP => 1);

sub fixture {
	my ($name, $text) = @_;
	my $path = File::Spec->catfile($dir, $name);
	open my $fh, '>', $path or die "cannot write \"$path\": $!\n";
	print {$fh} $text;
	close $fh or die "cannot close \"$path\": $!\n";
	return $path;
}

my $csv = fixture('t.csv', "a,b\n1,2\n\n3,\"x\ny\"\n");
my $tsv = fixture('t.tsv', "# a\tb\n1\t2\n3\t4\n");
my %want = (
	$csv => [ { a => 1, b => 2 }, { a => 3, b => "x\ny" } ],
	$tsv => [ { a => 1, b => 2 }, { a => 3, b => 4 } ],
);

my @rs = (
	[ 'undef (slurp)',    undef ],
	[ 'a record length',  \3 ],
	[ "'' (paragraphs)",  '' ],
	[ 'a comma',          ',' ],
);
for my $r (@rs) {
	my ($label, $value) = @$r;
	for my $file ($csv, $tsv) {
		my ($ext) = $file =~ /(\.\w+)\z/;
		for my $path ([ 'fast path', [] ], [ 'closure', [ filter => { 0 => sub { 1 } } ] ]) {
			my $got = do { local $/ = $value; read_table($file, @{ $path->[1] }) };
			is_deeply $got, $want{$file}, "\$/ = $label: $ext, $path->[0]";
		}
	}
}

# A filter runs between two reads of the file, and must see the $/ its caller
# set, not the "\n" the parser reads with.
{
	my @seen;
	local $/;
	read_table($csv, filter => { 0 => sub { push @seen, $/; 1 } });
	is_deeply \@seen, [ undef, undef ], 'a filter sees the caller\'s $/';
	ok !defined $/, 'and $/ is still the caller\'s afterwards';
}

done_testing;
