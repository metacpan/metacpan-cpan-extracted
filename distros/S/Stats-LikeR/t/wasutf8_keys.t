#!/usr/bin/env perl
# A key perl stored downgraded keeps its UTF-8 flag in what a function builds.
#
# A `use utf8` literal such as "é" (U+00E9) is stored by perl as the single
# byte E9 with the hash entry flagged HVhek_WASUTF8, and keys() hands it back
# as the UTF-8 string it was.  Reading such a key through HePV()/HeUTF8() gives
# the Latin-1 byte and a FALSE flag, so up to 0.3427 every function that copied
# a column name or a row name that way returned the key as the bare byte E9:
# colnames() and the things built on it (melt's `variable` column, the keys
# fillna()/bfill() add to the rows of a hash of hashes, summary()'s and
# table_one()'s labels, which printed a lone E9), the outer keys of select_cols,
# drop_cols and rename_cols on a hash of hashes, the cells of drop_cols and
# rename_cols that were kept, transpose(), p_adjust(), filter() on a hash of
# hashes, and kruskal_test()'s group_stats.  The cases are this module's own:
# R and pandas have no such two-form string.  What each must give is what a flat
# perl hash gives, `keys %h`: a flagged string.

require 5.010;
use strict;
use warnings FATAL => 'all';
use utf8;
use Test::More;
use Stats::LikeR qw(colnames melt fillna bfill summary table_one select_cols
	drop_cols rename_cols transpose p_adjust kruskal_test filter dropna);

my $E = "é";

# Whether every key is the flagged string "é" (or, for the other names, plain).
sub flagged { my ($k) = @_; return utf8::is_utf8($k) && $k eq $E }
sub e_key { my ($h) = @_; my ($k) = grep { $_ eq $E } keys %$h; return defined $k && flagged($k) }
sub ok_key { my ($h, $name) = @_; ok(e_key($h), $name) }

my @aoh = ({ k => 1, $E => 2 }, { k => 3, $E => undef });
my %hoh = (r1 => { $E => 1, k => 2 }, r2 => { $E => undef, k => 4 }, $E => { $E => 5, k => 6 });
my %hoa = ($E => [1, undef, 3], k => [4, 5, 6]);

# colnames
{
	my ($c) = grep { $_ eq $E } colnames(\@aoh);
	ok(flagged($c), 'colnames: an AoH column');
	($c) = grep { $_ eq $E } colnames(\%hoh);
	ok(flagged($c), 'colnames: a HoH column');
}

# melt: the variable column is the column names
{
	my $m = melt(\@aoh, id_vars => ['k']);
	my ($v) = grep { $_ eq $E } map { $_->{variable} } @$m;
	ok(flagged($v), 'melt: variable cell of an AoH');
	$m = melt(\%hoa, id_vars => ['k']);
	($v) = grep { $_ eq $E } map { ref $m eq 'HASH' ? @{ $m->{variable} } : $_->{variable} } (ref $m eq 'HASH' ? 1 : @$m);
	ok(flagged($v), 'melt: variable cell of a HoA');
}

# fillna / bfill add the missing columns to every row
for my $f ([ fillna => sub { fillna($_[0], value => 0) } ], [ bfill => sub { bfill($_[0]) } ]) {
	my ($name, $code) = @$f;
	my $r = $code->({ r1 => { k => 1 }, r2 => { k => 2, $E => 7 } });
	ok_key($r->{r1}, "$name: a key added to a HoH row");
	$r = $code->([ { k => 1 }, { k => 2, $E => 7 } ]);
	ok_key($r->[0], "$name: a key added to an AoH row");
}

# summary and table_one labels
{
	my $s = summary(\@aoh, return_only => 1);
	ok($s =~ /^\xc3\xa9 /m, "summary: the label prints as UTF-8 (C3 A9), not the lone byte E9");
	ok($s !~ /^\xe9/m, "summary: no bare E9 byte");
	my @d = map { { g => $_ % 2 ? 'a' : 'b', $E => $_ * 1.5, k => $_ } } 1 .. 10;
	my $t = table_one(\@d, by => 'g', vars => [$E, 'k']);
	my ($v) = grep { $_ eq $E } map { $_->{variable} } @$t;
	ok(flagged($v), 'table_one: the variable label');
}

# the column verbs
{
	my $r = select_cols(\%hoh, [$E]);
	ok_key($r, 'select_cols: the HoH outer key');
	ok_key($r->{r1}, 'select_cols: the selected column');
	$r = drop_cols(\%hoh, ['k']);
	ok_key($r, 'drop_cols: the HoH outer key');
	ok_key($r->{r1}, 'drop_cols: a kept HoH column');
	ok_key(drop_cols(\@aoh, ['k'])->[0], 'drop_cols: a kept AoH column');
	$r = rename_cols(\%hoh, { k => 'z' });
	ok_key($r, 'rename_cols: the HoH outer key');
	ok_key($r->{r1}, 'rename_cols: a column left alone, HoH');
	ok_key(rename_cols(\@aoh, { k => 'z' })->[0], 'rename_cols: a column left alone, AoH');
	$r = rename_cols(\@aoh, { $E => 'e' });
	ok(exists $r->[0]{e} && !exists $r->[0]{$E}, 'rename_cols: the flagged key is found in the map');
	ok_key(rename_cols([ { k => 1 } ], { k => $E })->[0], 'rename_cols: a new name that is flagged');
}

# transpose, both levels
{
	my $r = transpose(\%hoh);
	ok_key($r, 'transpose: the column that became a row key');
	ok_key($r->{k}, 'transpose: the row that became a column key');
	is($r->{k}{$E}, 6, 'transpose: the value under the flagged key');
}

# p_adjust, rows and columns
{
	my %ph = (r1 => { $E => 0.01, k => 0.02 }, $E => { $E => 0.03, k => 0.04 });
	my $r = p_adjust(\%ph);
	ok_key($r, 'p_adjust: the HoH outer key');
	ok_key($r->{r1}, 'p_adjust: the inner key');
	$r = p_adjust({ $E => [0.01, 0.02], k => [0.03, 0.04] });
	ok_key($r, 'p_adjust: the HoA column key');
}

# filter on a HoH keeps its row names; kruskal_test names its groups; dropna
{
	ok_key(filter(\%hoh, sub { 1 }), 'filter: a HoH row name, predicate');
	my $kr = kruskal_test({ $E => [1, 2, 3, 4], k => [5, 6, 7, 9] });
	ok_key($kr->{group_stats}{mean}, 'kruskal_test: group_stats mean');
	ok_key($kr->{group_stats}{size}, 'kruskal_test: group_stats size');
	ok_key(dropna(\%hoa, cols => ['k']), 'dropna: a HoA column key');
}

done_testing;
