#!/usr/bin/env perl
# read_table: regressions found in a review of 0.3213's CSV and VCF paths, and
# fixed in the same release. Each block names what used to happen. They were
# found by reading LikeR.xs and lib/Stats/LikeR.pm and confirmed by running each
# case against the 0.3212 build; the .xlsx cases from the same review are in
# t/read_table.xlsx.parser.t, beside the tokenizer they exercise.
#
# There is no R or SciPy suite to take these from. 'filter', the commented-out
# header, explode and the shapes are this module's own surface, so the expected
# values are what the documentation says, worked out by hand from the fixtures
# written below. The one outside reference is for the compressed formats this
# reader cannot inflate: their magic numbers are R's, from
# comp_type_from_memory() in src/main/connections.c (R 4.6.1), and zstd's is
# RFC 8878 section 3.1.1's Magic_Number, 0xFD2FB528 written little-endian.
require 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::Exception;
use File::Temp ();
use File::Spec ();
use Stats::LikeR qw(read_table);

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
	my ($name, $bytes) = @_;
	my $path = File::Spec->catfile($dir, $name);
	open my $fh, '>', $path or die "$path: $!";
	binmode $fh;
	print {$fh} $bytes;
	close $fh or die "$path: $!";
	return $path;
}

# The warnings a call gives, in order, with its result.
sub warned {
	my ($code) = @_;
	my @w;
	local $SIG{__WARN__} = sub { push @w, $_[0] };
	my $r = $code->();
	return ($r, @w);
}

my $vcf_head = "##fileformat=VCFv4.2\n"
	. join("\t", '#CHROM', qw(POS ID REF ALT QUAL FILTER INFO FORMAT));

# VCF explode with two output columns of one name. A sample name repeated in
# the header is the usual way to get one (merged files have them); a sample
# "X" with a FORMAT key "Y.Z" beside a sample "X.Y" with a key "Z" is another.
# Up to 0.3213 a hoa freed the first column's array while still pushing into
# it -- "realloc(): invalid pointer" and an abort -- and an aoh or hoh kept
# the later column silently, where the plain read warns about a repeated name.
{
	my $f = fixture('dup.vcf', "$vcf_head\tS1\tS1\n"
		. "1\t10\t.\tA\tC\t.\t.\t.\tGT:DP\t0/1:5\t1/1:7\n"
		. "1\t20\t.\tA\tG\t.\t.\t.\tGT:DP\t0/0:3\t0/1:4\n");
	my $warn = "read_table: duplicate column name(s) in $f (later values win): "
		. "'S1.GT' x 2 (fields 9, 11); 'S1.DP' x 2 (fields 10, 12)\n";
	my %fixed = (CHROM => 1, ID => '.', QUAL => '.', FILTER => '.', INFO => '.', REF => 'A');
	my @rows = (
		{ %fixed, POS => 10, ALT => 'C', 'S1.GT' => '1/1', 'S1.DP' => 7 },
		{ %fixed, POS => 20, ALT => 'G', 'S1.GT' => '0/1', 'S1.DP' => 4 },
	);
	my ($r, @w) = warned(sub { read_table($f, 'output_type' => 'hoa') });
	is_deeply $r, { map { my $k = $_; ($k => [ map { $_->{$k} } @rows ]) } keys %{ $rows[0] } },
		'repeated sample name, hoa: the later column, and no crash';
	is_deeply \@w, [$warn], '... warned about once, in the plain read\'s words';
	($r, @w) = warned(sub { read_table($f, 'output_type' => 'aoh') });
	is_deeply $r, \@rows, 'repeated sample name, aoh: the later column';
	is_deeply \@w, [$warn], '... and warned about';
	($r, @w) = warned(sub { read_table($f) });
	is_deeply $r, { '1:10:A:C' => $rows[0], '1:20:A:G' => $rows[1] },
		'repeated sample name, hoh (the default): the later column';
	is_deeply \@w, [$warn], '... and warned about';
	($r, @w) = warned(sub { read_table($f, 'output_type' => 'aoa') });
	is_deeply $r, [ [qw(CHROM POS ID REF ALT QUAL FILTER INFO S1.GT S1.DP S1.GT S1.DP)],
		[1, 10, '.', 'A', 'C', '.', '.', '.', '0/1', 5, '1/1', 7],
		[1, 20, '.', 'A', 'G', '.', '.', '.', '0/0', 3, '0/1', 4] ],
		'repeated sample name, aoa: every column kept, as an aoa keeps a repeated name';
	is_deeply \@w, [], '... with no warning';
	# row_names naming a repeated column keys by the later one, and neither
	# column is left among the row's values
	($r, @w) = warned(sub { read_table($f, 'row_names' => 'S1.DP') });
	my %by_dp = map { my %h = %$_; my $k = delete $h{'S1.DP'}; ($k => \%h) } @rows;
	is_deeply $r, \%by_dp, 'row_names on a repeated column keys by its later field';

	my $g = fixture('collide.vcf', "$vcf_head\tX\tX.Y\n"
		. "1\t10\t.\tA\tC\t.\t.\t.\tZ:Y.Z\tp:q\tr:s\n");
	($r, @w) = warned(sub { read_table($g, 'output_type' => 'hoa') });
	is_deeply [ @$r{qw(X.Z X.Y.Z X.Y.Y.Z)} ], [ ['p'], ['r'], ['s'] ],
		'a sample and key that collide with another sample\'s: the later column';
	is_deeply \@w, ["read_table: duplicate column name(s) in $g (later values win): "
		. "'X.Y.Z' x 2 (fields 10, 11)\n"], '... warned about';
}

# A commented-out header is cut by the parser itself. Up to 0.3213 it was cut
# by a perl split(), which ignored quoting and cut on the separator before the
# marker came off, so "# "x,y",z" was three names and "#<TAB>a<TAB>b" was
# ('', 'a', 'b'). Either way its width no longer matched the data's, so the
# first data row was promoted to the header and lost, without a warning.
{
	my $f = fixture('qhdr.csv', qq{# "x,y",z\n1,2\n3,4\n});
	is_deeply read_table($f), [ { 'x,y' => 1, z => 2 }, { 'x,y' => 3, z => 4 } ],
		'a commented-out header with a quoted separator in a name';
	$f = fixture('tabhdr.tsv', "#\ta\tb\n1\t2\n3\t4\n");
	is_deeply read_table($f), [ { a => 1, b => 2 }, { a => 3, b => 4 } ],
		'a tab after the marker of a tab-separated commented-out header';
	is_deeply read_table($f, sep => qr/\t/), [ { a => 1, b => 2 }, { a => 3, b => 4 } ],
		'... and with the tab given as a regex';
	is_deeply read_table($f, 'output_type' => 'aoa'), [ [qw(a b)], [1, 2], [3, 4] ],
		'... and as an aoa';
	# A comment holding an odd number of '"' is cut with quoting off, as no
	# one-line row of quoted fields has one: it is prose, and still a comment.
	$f = fixture('prose.csv', qq{# 5'10" tall, says the note\nid,val\n1,2\n});
	my ($r, @w) = warned(sub { read_table($f) });
	is_deeply $r, [ { id => 1, val => 2 } ], 'a comment with a lone \'"\' before the real header';
	is_deeply \@w, [], '... reads without a warning about the quote';
}

# Filter keys. Up to 0.3213 a field named by two keys -- its number and its
# name -- ran only one of them, and which one followed hash order, so the
# rows kept changed from run to run; and a numeric key was always a field
# number, so a column named "2021" could not be filtered on by name.
{
	my $f = fixture('ids.csv', "id,val\n1,a\n2,b\n3,c\n");
	my %seen;
	for my $run (1 .. 20) {
		# a fresh hash each run, whose keys perl iterates in its own order
		my $d = read_table($f, filter => { 1 => sub { $_ ne '1' }, id => sub { $_ ne '3' } });
		$seen{ join ',', map { $_->{id} } @$d }++;
	}
	is_deeply \%seen, { 2 => 20 }, 'a field named by number and by name runs both filters, every time';
	my @order;
	read_table($f, filter => { id => sub { push @order, "id:$_"; 1 }, 1 => sub { push @order, "1:$_"; 1 } });
	is_deeply \@order, [ '1:1', 'id:1', '1:2', 'id:2', '1:3', 'id:3' ],
		'... in the order of the keys, sorted';

	$f = fixture('years.csv', "2020,2021\n5,6\n7,8\n");
	is_deeply read_table($f, filter => { 2021 => sub { $_ > 6 } }),
		[ { 2020 => 7, 2021 => 8 } ], 'a key that is a column\'s name, all digits, is that column';
	$f = fixture('swapped.csv', "2,1\na,b\nc,d\n");
	is_deeply read_table($f, filter => { 1 => sub { $_ eq 'd' } }), [ { 2 => 'c', 1 => 'd' } ],
		'a name comes before a field number: key 1 is the column named 1, the second field';
	throws_ok { read_table($f, filter => { 3 => sub { 1 } }) }
		qr/^read_table: numeric filter key 3 exceeds the 2 columns of \Q$f\E, and no column is named '3'$/,
		'a number past the last field, naming no column';
	$f = fixture('plain.csv', "a,b\n1,x\n2,y\n");
	is_deeply read_table($f, filter => { 2 => sub { $_ eq 'y' } }), [ { a => 2, b => 'y' } ],
		'a number naming no column is still a field number';
	$f = fixture('zero.csv', "0,a\n1,x\n2,y\n");
	my @row0;
	read_table($f, filter => { 0 => sub { push @row0, ref $_; 1 } });
	is_deeply \@row0, [ 'ARRAY', 'ARRAY' ], 'key 0 is the whole row even when a column is named 0';
}

# A filter on a field whose name a later field repeats. %line_hash holds the
# later field's value ("later values win"), so the earlier field's filter sees
# its own value as $_, and what it writes back reaches that field and not the
# name's value. Up to 0.3213 it saw the later field's value, and its write-back
# replaced the name's value with its own.
{
	my $f = fixture('rep.csv', "a,b,a\n1,2,3\n");
	my @saw;
	my ($r) = warned(sub { read_table($f, filter => { 1 => sub { push @saw, $_; $_ = 'X'; 1 } }) });
	is_deeply \@saw, [1], 'a filter on the first of a repeated name sees that field\'s own value';
	is_deeply $r, [ { a => 3, b => 2 } ], '... and its write-back does not override the later field';
	($r) = warned(sub { read_table($f, 'output_type' => 'aoa',
		filter => { 1 => sub { $_ = 'X'; 1 } }) });
	is_deeply $r, [ [qw(a b a)], ['X', 2, 3] ], '... while an aoa keeps it, in its own field';
	@saw = ();
	warned(sub { read_table($f, filter => { a => sub { push @saw, $_; 1 } }) });
	is_deeply \@saw, [3], 'a filter keyed by the repeated name is on its later field';
}

# Text the caller holds as characters is compared as UTF-8 bytes, which is how
# every field is read. A literal sep or comment already was (the parser takes
# its bytes), but a qr// sep with a character past 0xFF never matched, and
# neither did such an na_strings token, filter key or row_names.
{
	my $dash = "\x{2014}";	# EM DASH, held in UTF-8 form
	my $f = fixture('dash.txt', "a\xe2\x80\x94b\n1\xe2\x80\x942\n\xe2\x80\x943\n");
	is_deeply read_table($f, sep => $dash), [ { a => 1, b => 2 }, { a => undef, b => 3 } ],
		'a separator given as a character string, for comparison';
	is_deeply read_table($f, sep => qr/$dash/), [ { a => 1, b => 2 }, { a => undef, b => 3 } ],
		'a qr// separator holding a character past 0xFF';
	my $runs = fixture('dashes.txt', "a\xe2\x80\x94\xe2\x80\x94b\n1\xe2\x80\x94\xe2\x80\x94\xe2\x80\x942\n");
	is_deeply read_table($runs, sep => qr/$dash+/), [ { a => 1, b => 2 } ],
		'... quantified as a character, not as its last byte';
	my $g = fixture('na.csv', "a,b\n\xe2\x80\x94,2\n1,\xe2\x80\x94\n");
	is_deeply read_table($g, 'na_strings' => $dash), [ { a => undef, b => 2 }, { a => 1, b => undef } ],
		'an na_strings token held as characters';
	is_deeply read_table($g, 'na_strings' => $dash, filter => { 0 => sub { 1 } }),
		[ { a => undef, b => 2 }, { a => 1, b => undef } ], '... and through the callback path';
	my $h = fixture('names.csv', "Donn\xc3\xa9es,n\nx,1\ny,2\n");
	my $name = "Donn\x{e9}es";
	utf8::upgrade($name);	# held in UTF-8 form, as under `use utf8`
	is_deeply read_table($h, filter => { $name => sub { $_ eq 'y' } }),
		[ { "Donn\xc3\xa9es" => 'y', n => 2 } ], 'a filter key held as characters';
	is_deeply read_table($h, 'output_type' => 'hoh', 'row_names' => $name),
		{ x => { n => 1 }, y => { n => 2 } }, 'a row_names held as characters';
	# The engine is told the line is UTF-8 only once it has been checked to be.
	my $bad = fixture('latin1.txt', "a\xe2\x80\x94b\n\xe9\xe2\x80\x942\n");
	throws_ok { read_table($bad, sep => qr/$dash/) }
		qr/^read_table: the sep regex .* holds characters beyond ASCII, so each line is matched as UTF-8, and line 2 of \Q$bad\E is not valid UTF-8$/,
		'a line that is not UTF-8, against a UTF-8 separator';
	# a pattern perl holds as bytes is matched against bytes, as before
	my $l1 = fixture('sect.txt', "a\xa7b\n1\xa72\n");
	is_deeply read_table($l1, sep => qr/\xa7/), [ { a => 1, b => 2 } ], 'a byte pattern on a Latin-1 file';
}

# Options that have no meaning for what was asked are refused, as row_names on
# an aoa and explode on a non-VCF already were. Up to 0.3213 they were ignored.
{
	my $f = fixture('opts.csv', "id,v\n1,2\n");
	for my $otype (qw(aoh hoa)) {
		throws_ok { read_table($f, 'output_type' => $otype, 'row_names' => 'id') }
			qr/^read_table: 'row_names' has no meaning for output_type "$otype"; the row names column is read as an ordinary column$/,
			"row_names with output_type $otype";
	}
	my $v = fixture('opts.vcf', "$vcf_head\tS\n1\t5\t.\tA\tC\t.\t.\t.\tGT\t0/1\n");
	throws_ok { read_table($v, 'output_type' => 'aoh', 'row_names' => 'nope') }
		qr/^read_table: 'row_names' has no meaning for output_type "aoh"/,
		'... on an exploded VCF as well';
	throws_ok { read_table($f, sheet => 2) }
		qr/^read_table: 'sheet' applies only to an \.xlsx, and "\Q$f\E" is not named as one$/,
		'sheet on a CSV';
	is_deeply read_table($f, sheet => undef), [ { id => 1, v => 2 } ], 'sheet => undef is no sheet';
}

# A compressed format this reader cannot inflate is named, not parsed as text:
# up to 0.3213 an .xz file came back as "Alignment error on x.csv.xz data row 2".
{
	my %magic = (
		xz   => "\xFD7zXZ\x00\x00\x04\xe6\xd6",
		lzma => "\x5D\x00\x00\x80\x00\xff\xff\xff\xff\xff",
		zstd => "\x28\xB5\x2F\xFD\x24\x0b\x59\x00\x00\x61",
		lzop => "\x89LZO\x00\x0d\x0a\x1a\x0a\x10",
	);
	$magic{'lzma (FF header)'} = "\xFFLZMA\x00\x01\x02\x03\x04";
	for my $codec (sort keys %magic) {
		(my $name = $codec) =~ s/ .*//;
		my $f = fixture("x.$name.csv", $magic{$codec} . "\x00" x 32);
		throws_ok { read_table($f) }
			qr/^read_table: "\Q$f\E" is $name-compressed, which read_table cannot decompress; decompress it first, or recompress it with gzip or bzip2$/,
			"$codec is refused by name";
	}
	# text that merely starts like one is text
	my $t = fixture('lzo.csv', "LZO,b\n1,2\n");
	is_deeply read_table($t), [ { LZO => 1, b => 2 } ], 'a text file starting "LZO" is text';
}

SKIP: {
	skip 'Test::LeakTrace not installed', 7 unless $HAVE_LEAKTRACE;
	skip 'running under Devel::Cover', 7 if $INC{'Devel/Cover.pm'};
	my $f = fixture('leak.vcf', "$vcf_head\tS1\tS1\n1\t10\t.\tA\tC\t.\t.\t.\tGT:DP\t0/1:5\t1/1:7\n");
	my $q = fixture('leakq.csv', qq{# "x,y",z\n1,2\n});
	my $u = fixture('leaku.txt', "a\xe2\x80\x94b\n1\xe2\x80\x942\n");
	my $bad = fixture('leakbad.txt', "a\xe2\x80\x94b\n\xe9\xe2\x80\x942\n");
	# compiled outside the blocks: 5.10.0's pp_qr() leaks an SV per qr//
	my $re = qr/\x{2014}/;
	local $SIG{__WARN__} = sub { };	# the repeated-name warnings
	for my $otype (qw(hoa aoh hoh)) {
		no_leaks_ok { read_table($f, 'output_type' => $otype) }
			"no leaks: explode with a repeated column name, $otype";
	}
	no_leaks_ok { read_table($q) } 'no leaks: a commented-out header cut by the parser';
	no_leaks_ok { read_table($u, sep => $re) } 'no leaks: a UTF-8 sep regex';
	no_leaks_ok { eval { read_table($bad, sep => $re) } } 'no leaks: a line refused as not UTF-8';
	no_leaks_ok { read_table($q, filter => { 1 => sub { 1 }, 'x,y' => sub { 1 } }) }
		'no leaks: two filters on one field';
}

done_testing();
