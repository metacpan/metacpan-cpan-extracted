#!/usr/bin/env perl
# read_table: cells of one column that hold the same text share one string.
#
# S_cell_shared() in LikeR.xs makes the second cell of a column to hold a text
# a shared hash key, and every later one a reference on that key, so a column
# of categories costs one buffer per category rather than one per cell. This
# file pins what that must not change -- every value, in every output shape,
# and that a write to one cell reaches no other -- and that the sharing does
# happen where it is meant to and not where it is not.
#
# Provenance. There is no reference implementation to take cases from: R and
# pandas do not hand out per-cell scalars, and the sharing is invisible in the
# values. The expected values are the text each file was written from, and
# every file is written here. Whether a cell shares is read from its SV with
# B: a shared hash key's scalar owns no buffer, so its LEN is 0, on every perl
# from 5.10 (sv.h; xlsx_sst_entry() in LikeR.xs relies on the same form).
#
# The numbers below are LikeR.xs's, and a test that depends on one says so:
# 32 remembered cells per column, in 16 sets of two (CSV_SEEN_SETS,
# CSV_SEEN_WAYS), a hit rate looked at every 256 probes (CSV_SEEN_WINDOW) and
# found wanting below 16 hits (CSV_SEEN_KEEP), and 4096 cells then passed by
# (CSV_SEEN_REST). Which set a text falls in is not pinned: where a count
# depends on it, the test states a bound and not the count.
require 5.010001;
use strict;
use warnings FATAL => 'all';
use Test::More;
use File::Temp ();
use File::Spec ();
use B ();
use Stats::LikeR qw(read_table);

our $HAVE_LEAKTRACE;
BEGIN {
	$HAVE_LEAKTRACE = eval {
		require Test::LeakTrace;
		Test::LeakTrace->import('no_leaks_ok');
		1;
	} ? 1 : 0;
}

my $dir = File::Temp::tempdir(CLEANUP => 1);
my $n_file = 0;
sub fixture {
	my ($text, $suffix) = @_;
	my $path = File::Spec->catfile($dir, 'f' . ++$n_file . ($suffix // '.csv'));
	open my $fh, '>', $path or die "cannot write \"$path\": $!\n";
	binmode $fh;
	print {$fh} $text;
	close $fh or die "cannot close \"$path\": $!\n";
	return $path;
}
# TRUE when the scalar's string is a shared hash key's rather than its own
sub shared { my $sv = B::svref_2object(\$_[0]); $sv->can('LEN') && $sv->LEN == 0 && defined $_[0] }

# ---- every shape returns the file's text ---------------------------------
# 600 rows: past one 256-probe window, so the id column (never repeating) is
# passed by while the category columns go on sharing.
my @sex  = qw(male female);
my @site = map { "site$_" } 0 .. 19;
my @rows = map { [ $_, $sex[$_ % 2], $site[ ($_ * 7) % 20 ], 'chr' . (1 + int($_ / 100)) ] } 1 .. 600;
my $csv  = fixture(join '', "id,sex,site,chr\n", map { join(',', @$_) . "\n" } @rows);

{
	my $aoh = read_table($csv);
	is(scalar @$aoh, 600, 'aoh: 600 rows');
	is_deeply($aoh, [ map { { id => $_->[0], sex => $_->[1], site => $_->[2], chr => $_->[3] } } @rows ],
		'aoh: every value is the file\'s');
	my $hoa = read_table($csv, output_type => 'hoa');
	is_deeply($hoa, { id => [ map { $_->[0] } @rows ], sex => [ map { $_->[1] } @rows ],
		site => [ map { $_->[2] } @rows ], chr => [ map { $_->[3] } @rows ] },
		'hoa: every value is the file\'s');
	my $aoa = read_table($csv, output_type => 'aoa');
	is_deeply($aoa, [ [qw(id sex site chr)], @rows ], 'aoa: every value is the file\'s');
	my $hoh = read_table($csv, output_type => 'hoh');
	is_deeply($hoh, { map { $_->[0] => { sex => $_->[1], site => $_->[2], chr => $_->[3] } } @rows },
		'hoh: every value is the file\'s');

	# the sharing itself: the first cell to hold a text keeps its own buffer,
	# the second is the key, and the rest refer to it
	ok(!shared($hoa->{sex}[0]), 'the first cell to hold a text has its own buffer');
	ok(!shared($hoa->{sex}[1]), '... and so has the first to hold the other text');
	is(scalar(grep { shared($_) } @{ $hoa->{sex} }[2 .. 599]), 598,
		'every later cell of a two-value column shares');
	# 20 values in 16 sets of two: a set that three of them fall in drops one
	# now and then, so most cells share, and how many is the hash's business
	cmp_ok(scalar(grep { shared($_) } @{ $hoa->{site} }), '>=', 300,
		'a 20-value column in no order shares at least half its cells');
	is(scalar(grep { shared($_) } @{ $hoa->{chr} }), 600 - 7,
		'a sorted column shares all but each run\'s first cell');
	is(scalar(grep { shared($_) } @{ $hoa->{id} }), 0, 'a column that never repeats shares nothing');
	is(scalar(grep { shared($_->{sex}) } @$aoh), 598, 'aoh cells share too');
	is(scalar(grep { shared($_->[1]) } @$aoa), 598, 'aoa cells share too');
	is(scalar(grep { shared($_->{sex}) } values %$hoh), 598, 'hoh cells share too');
}

# ---- a write to one cell reaches no other --------------------------------
{
	my $hoa = read_table($csv, output_type => 'hoa');
	my $col = $hoa->{sex};
	# odd indices: ids 2, 4, ..., whose sex is "male", every one of them shared
	ok(shared($col->[$_]), "cell $_ is shared before it is written") for 3, 5, 7, 9, 11;
	$col->[3] .= '!';		# append in place
	$col->[5]  = 'other';	# assign
	substr($col->[7], 0, 1) = 'M';	# lvalue substr
	$col->[9] =~ s/a/A/;
	chop $col->[11];
	is($col->[3],  'male!',  'append to a shared cell');
	is($col->[5],  'other',  'assign to a shared cell');
	is($col->[7],  'Male',   'substr write to a shared cell');
	is($col->[9],  'mAle',   's/// on a shared cell');
	is($col->[11], 'mal',    'chop on a shared cell');
	is(scalar(grep { $_ eq 'male' } @$col), 300 - 5, 'the other 295 "male" cells are untouched');
	is(scalar(grep { $_ eq 'female' } @$col), 300, '... and so is every "female"');
	# numeric use of a shared cell upgrades that cell alone. "7.0" and not
	# "7": an integer's text is stored as an IV, which is not shared at all
	# (t/read_table.int_cells.t)
	my $nums = read_table(fixture("k,v\n" . join('', map { "$_,7.0\n" } 1 .. 10)), output_type => 'hoa');
	ok(shared($nums->{v}[3]), 'a repeated decimal is shared text');
	$nums->{v}[3] += 1;
	is_deeply($nums->{v}, [ '7.0', '7.0', '7.0', 8, ('7.0') x 6 ], 'arithmetic on a shared cell changes that cell only');
}

# ---- more values than there are remembered cells --------------------------
# 200 texts through 32 remembered cells: most probes miss and evict, and every
# value still reads back as itself, among them texts that are prefixes of one
# another and texts that differ only in the middle.
{
	my @v = ((map { 'v' x $_ } 1 .. 100), (map { "a${_}z" } 1 .. 100));
	my @col = map { $v[ ($_ * 13) % 200 ] } 0 .. 1999;
	my $hoa = read_table(fixture(join '', "v\n", map { "$_\n" } @col), output_type => 'hoa');
	is_deeply($hoa->{v}, \@col, '200 values through 32 remembered cells read back as themselves');
	# runs of each do share, whatever set each falls in
	my @run = map { $v[ int($_ / 10) ] } 0 .. 1999;
	my $h2 = read_table(fixture(join '', "v\n", map { "$_\n" } @run), output_type => 'hoa');
	is_deeply($h2->{v}, \@run, 'runs of 200 values read back as themselves');
	is(scalar(grep { shared($_) } @{ $h2->{v} }), 2000 - 200, '... and share within each run');
	# a text longer than the 32 bytes the hash reads whole: texts that differ
	# only in the middle fall in one set, and are still told apart
	my @long = map { ('L' x 20) . $_ . ('R' x 20) } qw(a b c);
	my @lcol = map { $long[$_ % 3] } 0 .. 299;
	my $h3 = read_table(fixture(join '', "v\n", map { "$_\n" } @lcol), output_type => 'hoa');
	is_deeply($h3->{v}, \@lcol, 'long texts that differ only in the middle read back as themselves');
}

# ---- a column passed by is tried again ------------------------------------
# 256 unique cells close the first window with no hit, so the next 4096 cells
# are passed by; the constant text after them is then found and shared.
{
	my @col = ((map { "u$_" } 1 .. 256), ('same') x 4500);
	my $hoa = read_table(fixture(join '', "v\n", map { "$_\n" } @col), output_type => 'hoa');
	is_deeply($hoa->{v}, \@col, 'a column that turns constant reads back as itself');
	is(scalar(grep { shared($_) } @{ $hoa->{v} }[256 .. 256 + 4095]), 0,
		'the 4096 cells after a window with no hit are not probed');
	is(scalar(grep { shared($_) } @{ $hoa->{v} }[256 + 4096 + 1 .. $#col]), 4500 - 4096 - 1,
		'... and the column shares again once it is tried');
}

# ---- what must not be shared, or is not text -------------------------------
{
	# empty and na_strings cells are undef, and stay so beside shared ones
	my $f = fixture("a,b\n" . join('', map { ($_ % 3 ? 'x' : $_ % 2 ? '' : 'NA') . ",y\n" } 1 .. 60));
	my $hoa = read_table($f, output_type => 'hoa', na_strings => 'NA');
	is_deeply($hoa->{a}, [ map { $_ % 3 ? 'x' : undef } 1 .. 60 ], 'empty and na_strings cells are undef');
	is(scalar(grep { shared($_) } @{ $hoa->{a} }), 40 - 1, '... and the text between them shares');
	# a colClasses column holds numbers, not shared text
	my $g = fixture("n,s\n" . join('', map { "5,five\n" } 1 .. 20));
	my $cls = read_table($g, output_type => 'hoa', colClasses => { n => 'integer' });
	is_deeply($cls->{n}, [ (5) x 20 ], 'a colClasses column is its numbers');
	is(scalar(grep { shared($_) } @{ $cls->{n} }), 0, '... and none of them is a shared string');
	is(scalar(grep { shared($_) } @{ $cls->{s} }), 19, '... while the text column beside it shares');
	# a filter is handed the text and may keep or change it: its rows are not
	# built by this path, and read as they always have
	my $flt = read_table($csv, output_type => 'hoa', filter => { sex => sub { $_ eq 'male' } });
	is_deeply($flt->{sex}, [ ('male') x 300 ], 'a filtered read returns the rows it kept');
	# quoted fields, assembled in the accumulator, share as plain ones do
	my $q = fixture("a,b\n" . join('', map { qq("x, ""y""",z\n) } 1 .. 30));
	my $qh = read_table($q, output_type => 'hoa');
	is_deeply($qh->{a}, [ ('x, "y"') x 30 ], 'quoted fields read back as their text');
	is(scalar(grep { shared($_) } @{ $qh->{a} }), 29, '... and share');
	# bytes >= 0x80 stay bytes: no UTF-8 flag, no downgrade
	my $u = fixture("a\n" . join('', map { "caf\xC3\xA9\n" } 1 .. 10));
	my $uh = read_table($u, output_type => 'hoa');
	is(scalar(grep { $_ eq "caf\xC3\xA9" && !utf8::is_utf8($_) } @{ $uh->{a} }), 10,
		'UTF-8 bytes come back as the same unflagged bytes, shared or not');
	# a single-byte text: its first and last byte are the same byte
	my $one = read_table(fixture("a\n" . ("T\nF\n" x 50)), output_type => 'hoa');
	is_deeply($one->{a}, [ map { $_ % 2 ? 'F' : 'T' } 0 .. 99 ], 'one-byte texts read back as themselves');
}

# ---- a hoh's repeated row name frees the cells it replaces ----------------
{
	my $f = fixture("k,v\n" . join('', map { 'r' . ($_ % 5) . ",val\n" } 1 .. 50));
	my $hoh;
	{
		local $SIG{__WARN__} = sub { };	# "rows repeat an earlier row's name": not this test's subject
		$hoh = read_table($f, output_type => 'hoh');
	}
	is_deeply($hoh, { map { ("r$_" => { v => 'val' }) } 0 .. 4 }, 'a hoh with repeated row names keeps the last of each');
}

# ---- a ragged row still dies as it did -------------------------------------
{
	my $f = fixture("a,b\n" . ("x,y\n" x 5) . "x,y,z\n");
	eval { read_table($f) };
	like($@, qr/\AAlignment error on \Q$f\E data row 6 \(3 fields vs 2 headers\)/,
		'a row wider than the header dies with the alignment message');
}

# ---- gzip input goes through the same path --------------------------------
SKIP: {
	skip 'Compress::Raw::Zlib not available', 2 unless eval { require Compress::Raw::Zlib; 1 };
	my ($d) = Compress::Raw::Zlib::Deflate->new(-WindowBits => Compress::Raw::Zlib::WANT_GZIP());
	my $text = join '', "id,sex\n", map { "$_," . $sex[$_ % 2] . "\n" } 1 .. 600;
	my ($out, $tail) = ('', '');
	$d->deflate($text, $out);
	$d->flush($tail);
	my $hoa = read_table(fixture($out . $tail, '.csv.gz'), output_type => 'hoa');
	is_deeply($hoa->{sex}, [ map { $sex[$_ % 2] } 1 .. 600 ], 'a gzip read returns the text');
	is(scalar(grep { shared($_) } @{ $hoa->{sex} }), 598, '... with its cells shared');
}

# ---- leaks ----------------------------------------------------------------
SKIP: {
	skip 'Test::LeakTrace not installed', 5 unless $HAVE_LEAKTRACE;
	my $ragged = fixture("a,b\n" . ("x,y\n" x 300) . "x,y,z\n");
	no_leaks_ok { read_table($csv) } 'no leaks: aoh';
	no_leaks_ok { read_table($csv, output_type => 'hoa') } 'no leaks: hoa';
	no_leaks_ok { read_table($csv, output_type => 'aoa') } 'no leaks: aoa';
	no_leaks_ok { read_table($csv, output_type => 'hoh') } 'no leaks: hoh';
	no_leaks_ok { eval { read_table($ragged) } } 'no leaks: a croak with cells remembered';
}

done_testing;
