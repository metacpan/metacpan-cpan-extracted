#!/usr/bin/env perl
# read_table has two ways of turning a parsed CSV into the shape the caller
# asked for, and this pins them to each other.
#
# The default is the fast path: once the header is fixed, _parse_csv_file is
# handed a plan (csv_plan in LikeR.xs) and assembles every remaining row in C.
# The older path hands each row to a perl closure instead, and is still what
# runs for a 'filter' (and, until 0.319, for 'hoh'). So every case below is read
# twice -- once as-is, and once with a filter that accepts every row, which is
# the shortest way to force the closure -- and the two results must be
# identical. A no-op filter cannot change what comes back: a key of 0 gives the
# callback the whole row, and read_table only writes a mutated $_ back for keys
# above 0.
#
# There is no R or SciPy suite to take these from: output_type, the filter
# callbacks and auto_row_names are this module's own surface, and what is being
# checked is that two of its internal paths agree, not that either matches a
# reference. The values themselves are the fixtures written below.
require 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;
use File::Temp ();
use File::Spec ();
use Stats::LikeR qw(read_table write_table);

my $HAVE_LEAKTRACE;
BEGIN {
	$HAVE_LEAKTRACE = eval {
		require Test::LeakTrace;
		Test::LeakTrace->import('no_leaks_ok');
		1;
	} ? 1 : 0;
}

my $dir = File::Temp::tempdir(CLEANUP => 1);

sub fixture {
	my ($name, $text) = @_;
	my $path = File::Spec->catfile($dir, $name);
	open my $fh, '>', $path or die "cannot write \"$path\": $!\n";
	print {$fh} $text;
	close $fh or die "cannot close \"$path\": $!\n";
	return $path;
}

# A row count above one field-buffer's worth of rows is not needed: the plan is
# picked up after the first data row, so anything with two or more data rows
# exercises it. Three are used so that "later values win" and the ragged-row
# message both have a row to be wrong about.
my %f = (
	plain   => fixture('plain.csv',   "a,b\n1,2\n3,4\n5,6\n"),
	dup     => fixture('dup.csv',     "a,b,a\n1,2,3\n4,5,6\n7,8,9\n"),
	empty   => fixture('empty.csv',   "a,b\n1,\n,2\n,\nNA,x\n"),
	quoted  => fixture('quoted.csv',
		qq{a,b,c\n"x,1","he said ""hi""",3\n"multi\nline",2,3\n}),
	hdronly => fixture('hdronly.csv', "a,b\n"),
	onerow  => fixture('onerow.csv',  "a,b\n1,2\n"),
	autorn  => fixture('autorn.csv',  "x,y\nA,1,2\nB,3,4\nC,5,6\n"),
	cmt     => fixture('cmt.tsv',     "# a\tb\n1\t2\n3\t4\n5\t6\n"),
	tabs    => fixture('tabs.tsv',    "a\tb\n1\t2\n3\t4\n"),
	crlf    => fixture('crlf.csv',    "a,b\r\n1,2\r\n3,4\r\n"),
	onecol  => fixture('onecol.csv',  "a\n1\n2\n3\n"),
	ragged  => fixture('ragged.csv',  "a,b,c\n1,2,3\n4,5\n6,7,8\n"),
	duprn   => fixture('duprn.csv',   "id,v,w\nA,1,2\nB,3,4\nA,5,\n"),
	# three repeats, the first on data row 3
	dup3    => fixture('dup3.csv',    "id,v\nA,1\nB,2\nA,3\nB,4\nA,5\n"),
	undefrn => fixture('undefrn.csv', "id,v\nA,1\n,2\nC,3\n"),
	nark    => fixture('nark.csv',    "id,v\nA,1\nNA,2\n"),
	# Mostly empty: once the plan is on, an empty field is parsed straight to
	# undef (S_push_field() in LikeR.xs), and a header with an empty name has
	# to still be handed '' so that it becomes 'row_name'.
	sparse  => fixture('sparse.csv',  ",b,c\n1,,\n,,\n,2,\n,,3\n"),
	# a row of nothing but separators is a row of empty fields (0.321)
	tabrow  => fixture('tabrow.tsv',  "a\tb\n1\t2\n\t\n3\t4\n"),
	# a commented-out header one field short of the data, for auto_row_names
	autocmt => fixture('autocmt.tsv', "# a\tb\nr1\t1\t2\nr2\t3\t4\n"),
	# \xe9 is Latin-1 e-acute, and \xe2\x82\xac the UTF-8 bytes of the euro sign
	bytes   => fixture('bytes.csv',   "a,b\n\xe9,1\n\xe2\x82\xac,2\nx,3\nNA,4\n"),
);

# na_strings is looked up by a linear scan up to NA_LINEAR_MAX (8) strings and in
# a hash past that (S_plan_na() in LikeR.xs), so both sizes are read.
my @na8 = ('NA', map { "n$_" } 1 .. 7);
my @na9 = (@na8, 'x');

# Each case is (label, file, extra read_table options).
my @cases = (
	[ 'plain',                   $f{plain},   [] ],
	[ 'duplicate column names',  $f{dup},     [] ],
	[ 'empty fields',            $f{empty},   [] ],
	[ 'na_strings',              $f{empty},   [ 'na_strings' => [ 'NA', 'x' ] ] ],
	[ 'na_strings, one string',  $f{empty},   [ 'na_strings' => 'NA' ] ],
	[ 'quoted, embedded comma',  $f{quoted},  [] ],
	[ 'header only',             $f{hdronly}, [] ],
	[ 'one data row',            $f{onerow},  [] ],
	[ 'auto_row_names',          $f{autorn},  [ 'auto_row_names' => 1 ] ],
	[ 'auto_row_names, named',   $f{autorn},  [ 'auto_row_names' => 'rn' ] ],
	[ 'commented-out header',    $f{cmt},     [] ],
	[ 'tab separated',           $f{tabs},    [] ],
	[ 'explicit sep',            $f{tabs},    [ sep => "\t" ] ],
	[ 'CRLF line endings',       $f{crlf},    [] ],
	[ 'single column',           $f{onecol},  [] ],
	[ 'mostly empty',            $f{sparse},  [] ],
	[ 'mostly empty, na_strings', $f{sparse}, [ 'na_strings' => '2' ] ],
	[ 'a row of separators',     $f{tabrow},  [] ],
	[ 'auto_row_names, commented header', $f{autocmt}, [ 'auto_row_names' => 1 ] ],
	[ 'na_strings, 8 strings',   $f{empty},   [ 'na_strings' => \@na8 ] ],
	[ 'na_strings, 9 strings',   $f{empty},   [ 'na_strings' => \@na9 ] ],
	# a character key that perl holds as bytes matches the Latin-1 byte; one it
	# holds in UTF-8 form is encoded to UTF-8 bytes, so the euro sign matches its
	# three bytes in the file (up to 0.3213 it matched nothing, on both paths)
	[ 'na_strings, character keys', $f{bytes}, [ 'na_strings' => [ "\x{e9}", "\x{20ac}" ] ] ],
	[ 'na_strings, byte keys',   $f{bytes},   [ 'na_strings' => [ "\xe2\x82\xac", 'NA' ] ] ],
);

# A hoh keys every row by its row_names column, so the cases that only make
# sense as one -- a repeated row name, a missing one, one that na_strings turns
# into a missing one, and an explicit row_names -- are added here.
push @cases,
	[ 'repeated row name',        $f{duprn},   [] ],
	[ 'three repeated row names', $f{dup3},    [] ],
	[ 'missing row name',         $f{undefrn}, [] ],
	[ 'na_strings row name',      $f{nark},    [ 'na_strings' => 'NA' ] ],
	[ 'explicit row_names',       $f{duprn},   [ 'row_names' => 'w' ] ],
	[ 'row_names, repeated col',  $f{dup},     [ 'row_names' => 'a' ] ];

# One read, as (result or undef, $@ or '', the warnings it raised). The
# duplicate-column warning is left out: it is raised once per read, from perl,
# whichever path builds the rows, and t/read_table.t already pins it.
sub read_all {
	my @args = @_;
	my @warn;
	local $SIG{__WARN__} = sub {
		push @warn, $_[0] unless $_[0] =~ /duplicate column name/;
	};
	my $r = eval { read_table(@args) };
	return [ $r, $@, \@warn ];
}

for my $case (@cases) {
	my ($label, $file, $opts) = @$case;
	for my $otype (qw(aoa aoh hoa hoh)) {
		my $fast   = read_all($file, @$opts, 'output_type' => $otype);
		my $closed = read_all($file, @$opts, 'output_type' => $otype,
			filter => { 0 => sub { 1 } });
		is_deeply $fast, $closed,
			"$label ($otype): both paths agree, errors and warnings included";
	}
}

# The hoh cases above agree with each other; these pin what they agree ON, so
# that both paths breaking the same way cannot pass.
{
	my $r = read_all($f{duprn}, 'output_type' => 'hoh');
	is_deeply $r->[0], { A => { v => 5, w => undef }, B => { v => 3, w => 4 } },
		'hoh: a repeated row name keeps the later values';
	is_deeply $r->[2],
		[ "read_table: duplicate row name 'A' in $f{duprn} (later values win)\n" ],
		'hoh: and warns once, naming it';
	# One warning for the file however many rows repeat a name: up to 0.3213
	# there was one per row.
	$r = read_all($f{dup3}, 'output_type' => 'hoh');
	is_deeply $r->[0], { A => { v => 5 }, B => { v => 4 } },
		'hoh: three repeats keep the latest values';
	is_deeply $r->[2],
		[ "read_table: 3 rows of $f{dup3} repeat an earlier row's name (later "
		. "values win); the first is 'A', on data row 3\n" ],
		'hoh: and warn once, with the count and the first';
	# An .xlsx is parsed by _parse_xlsx_sheet_xs(), which hands its count back
	# the same way
	my $xlsx = File::Spec->catfile(File::Temp::tempdir(CLEANUP => 1), 'dup3.xlsx');
	write_table([ [qw(id v)], [ 'A', 1 ], [ 'B', 2 ], [ 'A', 3 ], [ 'B', 4 ],
		[ 'A', 5 ] ], $xlsx, quiet => 1);
	for my $path ([ fast => [] ], [ filter => [ filter => sub { 1 } ] ]) {
		$r = read_all($xlsx, 'output_type' => 'hoh', @{ $path->[1] });
		is_deeply $r, [ { A => { v => 5 }, B => { v => 4 } }, '',
			[ "read_table: 3 rows of $xlsx repeat an earlier row's name (later "
			. "values win); the first is 'A', on data row 3\n" ] ],
			"hoh from an .xlsx ($path->[0] path): one warning";
	}
	$r = read_all($f{undefrn}, 'output_type' => 'hoh');
	is $r->[1],
		"read_table: undefined row name (column 'id') in $f{undefrn} data row 2\n",
		'hoh: a missing row name dies, naming the column and the row';
	$r = read_all($f{nark}, 'output_type' => 'hoh', 'na_strings' => 'NA');
	like $r->[1], qr/^read_table: undefined row name \(column 'id'\) .* data row 2$/,
		'hoh: so does one that na_strings makes missing';
	$r = read_all($f{nark}, 'output_type' => 'hoh');
	is_deeply $r->[0], { A => { v => 1 }, NA => { v => 2 } },
		'hoh: without na_strings, "NA" is an ordinary row name';
}

# The alignment message is produced by whichever path is reading, so the two
# have to spell it the same way -- including the data row number, which the
# fast path continues from wherever the closure stopped rather than restarting.
for my $otype (qw(aoa aoh hoa hoh)) {
	my $fast   = eval { read_table($f{ragged}, 'output_type' => $otype); 1 }
		? '' : $@;
	my $closed = eval { read_table($f{ragged}, 'output_type' => $otype,
		filter => { 0 => sub { 1 } }); 1 } ? '' : $@;
	like $fast,
		qr/\AAlignment error on \Q$f{ragged}\E data row 2 \(2 fields vs 3 headers\)\.$/m,
		"ragged row ($otype): fast path names the row and both counts";
	is $fast, $closed, "ragged row ($otype): both paths word it the same";
}

# The aoa cases above agree with each other; these pin what they agree ON. An
# aoa is the one shape that keeps every field of a repeated column name.
{
	my $r = read_all($f{dup}, 'output_type' => 'aoa');
	is_deeply $r->[0], [ [qw(a b a)], [1, 2, 3], [4, 5, 6], [7, 8, 9] ],
		'aoa: header row first, then every field of every row in file order';
	$r = read_all($f{empty}, 'output_type' => 'aoa', 'na_strings' => 'NA');
	is_deeply $r->[0], [ [qw(a b)], [1, undef], [undef, 2], [undef, undef], [undef, 'x'] ],
		'aoa: empty and na_strings cells are undef';
	$r = read_all($f{hdronly}, 'output_type' => 'aoa');
	is_deeply $r->[0], [ [qw(a b)] ], 'aoa: a header-only file is its header row';
	$r = read_all($f{duprn}, 'output_type' => 'aoa', 'row_names' => 'id');
	like $r->[1], qr/^read_table: 'row_names' has no meaning for output_type "aoa"/,
		'aoa: row_names is refused';
}

# undef, not "", is what an empty cell becomes -- the one value transformation
# the fast path makes, so check it by identity rather than through is_deeply.
{
	my $aoh = read_table($f{empty});
	ok !defined $aoh->[0]{b}, 'empty cell is undef in an aoh';
	my $hoa = read_table($f{empty}, 'output_type' => 'hoa');
	ok !defined $hoa->{b}[0], 'empty cell is undef in a hoa';
	my $na = read_table($f{empty}, 'na_strings' => 'NA');
	ok !defined $na->[3]{a}, 'an na_strings cell is undef too';
	is $na->[3]{b}, 'x', 'a cell that is not in na_strings is left alone';
}

# The cases added for 0.321 agree with each other; these pin what they agree ON.
{
	my $r = read_all($f{sparse});
	is_deeply $r->[0], [
		{ row_name => 1,     b => undef, c => undef },
		{ row_name => undef, b => undef, c => undef },
		{ row_name => undef, b => 2,     c => undef },
		{ row_name => undef, b => undef, c => 3 },
	], 'mostly empty: an empty header name is row_name, every empty cell undef';
	$r = read_all($f{sparse}, 'output_type' => 'hoa', 'na_strings' => '2');
	is_deeply $r->[0], { row_name => [1, undef, undef, undef],
		b => [undef, undef, undef, undef], c => [undef, undef, undef, 3] },
		'mostly empty: na_strings still applies beside the empty cells';
	$r = read_all($f{tabrow}, 'output_type' => 'aoa');
	is_deeply $r->[0], [ [qw(a b)], [1, 2], [undef, undef], [3, 4] ],
		'a row of separators is a row of undef';
	$r = read_all($f{autocmt}, 'auto_row_names' => 1);
	is_deeply $r->[0], [ { row_name => 'r1', a => 1, b => 2 },
		{ row_name => 'r2', a => 3, b => 4 } ],
		'auto_row_names: a commented-out header one field short is the header';
	$r = read_all($f{empty}, 'output_type' => 'aoa', 'na_strings' => \@na9);
	is_deeply $r->[0], [ [qw(a b)], [1, undef], [undef, 2], [undef, undef], [undef, undef] ],
		'na_strings, 9 strings: the hash lookup finds both NA and x';
	$r = read_all($f{empty}, 'output_type' => 'aoa', 'na_strings' => \@na8);
	is_deeply $r->[0], [ [qw(a b)], [1, undef], [undef, 2], [undef, undef], [undef, 'x'] ],
		'na_strings, 8 strings: the scan finds NA, and x is not one of them';
	$r = read_all($f{bytes}, 'output_type' => 'aoa', 'na_strings' => [ "\x{e9}", "\x{20ac}" ]);
	is_deeply $r->[0], [ [qw(a b)], [undef, 1], [undef, 2], ['x', 3], ['NA', 4] ],
		'na_strings, character keys: e-acute matches its byte, the euro sign its UTF-8 bytes';
	$r = read_all($f{bytes}, 'output_type' => 'aoa', 'na_strings' => [ "\xe2\x82\xac", 'NA' ]);
	is_deeply $r->[0], [ [qw(a b)], ["\xe9", 1], [undef, 2], ['x', 3], [undef, 4] ],
		'na_strings, byte keys: the euro sign\'s bytes match their own cell';
}

# A filter is perl, and has always been handed '' for an empty field, not the
# undef the fast path now parses one to.
{
	my @seen;
	read_table($f{sparse}, filter => { 0 => sub { push @seen, [ @{ $_[0] } ]; 1 } });
	is_deeply \@seen, [ [1, '', ''], ['', '', ''], ['', 2, ''], ['', '', 3] ],
		'a filter sees an empty field as the empty string';
}

# The plan is installed once and then never consulted again, so reading the
# same file twice through the same process has to give the same thing.
{
	my $first  = read_table($f{plain});
	my $second = read_table($f{plain});
	is_deeply $second, $first, 'a second read of the same file is unchanged';
}

SKIP: {
	skip 'Test::LeakTrace not installed', 17 unless $HAVE_LEAKTRACE;
	skip 'running under Devel::Cover', 17 if $INC{'Devel/Cover.pm'};

	no_leaks_ok { read_table($f{plain}) } 'no leaks: aoh fast path';
	no_leaks_ok { read_table($f{plain}, 'output_type' => 'hoa') }
		'no leaks: hoa fast path';
	no_leaks_ok { read_table($f{empty}, 'na_strings' => [ 'NA', 'x' ]) }
		'no leaks: na_strings';
	# a duplicate name leaves one parsed field with no column to go to, which
	# is the only place the fast path frees a cell rather than handing it on
	no_leaks_ok {
		local $SIG{__WARN__} = sub { };
		read_table($f{dup});
	} 'no leaks: duplicate column names';
	# the alignment croak unwinds out of the middle of a read
	no_leaks_ok { eval { read_table($f{ragged}) } }
		'no leaks: alignment error';
	no_leaks_ok { read_table($f{plain}, 'output_type' => 'hoh') }
		'no leaks: hoh fast path';
	no_leaks_ok { read_table($f{empty}, 'output_type' => 'aoa', 'na_strings' => 'NA') }
		'no leaks: aoa fast path';
	no_leaks_ok { eval { read_table($f{ragged}, 'output_type' => 'aoa') } }
		'no leaks: aoa alignment error';
	no_leaks_ok { read_table($f{plain}, 'output_type' => 'aoa', filter => { 0 => sub { 1 } }) }
		'no leaks: aoa through the closure';
	# the row-name croak unwinds with the row still full of cells
	no_leaks_ok { eval { read_table($f{undefrn}, 'output_type' => 'hoh') } }
		'no leaks: missing row name';
	# a __WARN__ handler that dies on the repeated-row-name warning, which is
	# raised from inside the fast path
	no_leaks_ok {
		local $SIG{__WARN__} = sub { die $_[0] };
		eval { read_table($f{duprn}, 'output_type' => 'hoh') };
	} 'no leaks: dying on the repeated-row-name warning';
	# compiled outside the blocks: 5.10.0's pp_qr() leaks an SV per qr//
	my $comma = qr/,/;
	my $empty = qr/(?=,)/;
	no_leaks_ok { read_table($f{plain}, sep => $comma) }
		'no leaks: a regex sep through the fast path';
	no_leaks_ok { read_table($f{sparse}, 'output_type' => 'aoa') }
		'no leaks: empty fields parsed straight to undef';
	no_leaks_ok { eval { read_table($f{sparse}, 'output_type' => 'hoh') } }
		'no leaks: an undef row name croaks with the row full of undef cells';
	no_leaks_ok { read_table($f{empty}, 'na_strings' => \@na8) }
		'no leaks: na_strings by the scan';
	no_leaks_ok { read_table($f{empty}, 'na_strings' => \@na9) }
		'no leaks: na_strings by the hash';
	# the empty-match croak unwinds out of the middle of a line
	no_leaks_ok { eval { read_table($f{plain}, sep => $empty) } }
		'no leaks: a regex sep that matches an empty string';
}

# The fast path stores into the plan's output arrays directly (S_av_push_own()
# in LikeR.xs), so S_plan_init() refuses one with magic. read_table's own never
# have any; this is what a plan from anywhere else gets.
{
	package Local::TiedAV; require Tie::Array; our @ISA = ('Tie::StdArray');
	package Local::TiedHV; require Tie::Hash;  our @ISA = ('Tie::StdHash');
}
{
	my $file = $f{duprn};
	my $try = sub {
		my ($mode, $out) = @_;
		my $p = {};
		my $z = 0;
		my $cb = sub {
			return if %$p;
			@$p{qw(keys idx ncol file row mode)}
				= ([qw(id v w)], [0, 1, 2], 3, $file, \$z, $mode);
			$p->{rn}  = 0 if $mode == 2;
			$p->{out} = $out;
		};
		return eval { Stats::LikeR::_parse_csv_file($file, ',', '#', $cb, $p); 1 }
			? '' : $@;
	};
	tie my @t, 'Local::TiedAV';
	like $try->(3, \@t), qr/^_parse_csv_file: plan 'out' is tied, magical or read-only/,
		'a tied output array is refused';
	tie my @c, 'Local::TiedAV';
	like $try->(1, [ [], \@c, [] ]),
		qr/^_parse_csv_file: plan 'out' column is tied, magical or read-only/,
		'a tied hoa column is refused';
	tie my %h, 'Local::TiedHV';
	like $try->(2, \%h), qr/^_parse_csv_file: plan 'out' is tied, magical or read-only/,
		'a tied hoh hash is refused';
}

done_testing;
