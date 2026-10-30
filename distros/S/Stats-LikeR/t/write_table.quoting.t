#!/usr/bin/env perl

# write_table's delimited output, its argument checks, and the header scan of
# an AoH or a HoH.
#
# Provenance of the expected bytes:
#
# - A record of one empty field is written '""', as CPython 3.14.2's csv.writer
#   writes it: Lib/test/test_csv.py, test_write_empty_fields
#   (_write_test([''], '""') and _write_test([None], '""'), each with csv's
#   default "\r\n" line terminator, where write_table ends a record with "\n")
#   and test_writerows_with_none ([[None], ['a']] -> '""\r\na\r\n' and
#   [['a'], [None]] -> 'a\r\n""\r\n').  Two or more empty fields are not
#   quoted there (_write_test(['', ''], ',')), and are not here either.
# - The separator messages follow csv.writer's refusals in the same version:
#   delimiter='' raises '"delimiter" must be a unicode character, not a string
#   of length 0', and delimiter='"' raises 'bad delimiter or quotechar value'.
#
# Everything else is a regression test built from the reproducer that found
# it, with the bytes frozen here:
#
# - a lone field of spaces or tabs, and a first field starting with '#', were
#   written bare, and read_table skipped the record (as a blank line, and as
#   a comment);
# - an undef in an AoA's col_names was skipped, and every later name moved one
#   column left;
# - a header cell that is a reference was written as its address;
# - sep => '', a sep holding a NUL, a quote, a CR or a LF, and a file name
#   holding a NUL were all taken without a word;
# - row_names => 'name' was ignored for an AoA or a flat hash, a HoA's
#   row_names naming no column gave every row an empty label, and AoH rows
#   missing it said nothing;
# - a restricted hash (Hash::Util::lock_keys) that lacked a column died
#   "Attempt to access disallowed key" partway through the file;
# - finding an AoH's or a HoH's columns iterated every row hash, which left an
#   iterator allocated on each (the OOK flag) for good.
# - with a separator of more than one byte, a field whose end and the
#   separator after it spelled the separator again was written bare: sep "::"
#   and the fields "a:", ":b" became "a::::b", which read_table cuts at the
#   first "::" it finds, as three fields.  The round trips below (fixed cases,
#   then 2000 generated tables) all failed somewhere on 0.33; the generator is
#   a fixed LCG so that the tables are the same on every run and srand() is
#   left alone.

require 5.010;
use strict;
use warnings FATAL => 'all';
use File::Temp qw(tempdir);
use Test::More;
use Test::Exception;
use Test::LeakTrace 'no_leaks_ok';
use Hash::Util qw(lock_keys);
use Tie::Hash;
use B ();
use Stats::LikeR qw(write_table read_table);

my $dir = tempdir(CLEANUP => 1);
my $seq = 0;
sub path { $seq++; return "$dir/q$seq." . (shift // 'csv') }
# write_table opens its file with PerlIO_open()'s default layers, which are
# :crlf where perl is a CRLF shop (Windows), so every "\n" it writes lands as
# "\r\n" there; 0.33's MSWin32 smoker failed 29 of these on that alone.
# :crlf maps "\n" and nothing else, so undoing it gives back exactly the text
# write_table wrote, a stray CR included, and the literals below stay in \n.
my $CRLF = do {
	open my $fh, '>', path('nl.probe') or die "cannot write a probe: $!";
	my $crlf = grep { $_ eq 'crlf' } PerlIO::get_layers($fh);
	close $fh;
	$crlf;
};
sub slurp {
	my $file = shift;
	open my $fh, '<:raw', $file or die "cannot read \"$file\": $!";
	local $/;
	my $text = <$fh>;
	$text =~ s/\r\n/\n/g if $CRLF;
	return $text;
}
# write, then the bytes written; warnings are kept in @W
our @W;
sub wbytes {
	my ($data, %opt) = @_;
	my $f = path($opt{_ext});
	delete $opt{_ext};
	local $SIG{__WARN__} = sub { push @W, $_[0] };
	write_table($data, $f, quiet => 1, %opt);
	return slurp($f);
}

# ---- a record of one empty field: CPython's test_write_empty_fields -----
is(wbytes([['a'], ['']]),    qq{a\n""\n},  "[''] is written '\"\"' (csv.writer)");
is(wbytes([['a'], [undef]]), qq{a\n""\n},  "[undef] is written '\"\"' (csv.writer, [None])");
is(wbytes([['a', 'b'], ['', '']]), qq{a,b\n,\n}, "['', ''] stays ',' (csv.writer)");
is(wbytes([['a', 'b'], [undef, undef]]), qq{a,b\n,\n}, "[undef, undef] stays ','");
# test_writerows_with_none: [[None], ['a']] and [['a'], [None]]
is(wbytes([[undef], ['a']], col_names => ['h']), qq{h\n""\na\n}, '[[None], [a]] (csv.writer)');
is(wbytes([['a'], [undef]], col_names => ['h']), qq{h\na\n""\n}, '[[a], [None]] (csv.writer)');
# undef_val is what an undef is written as, and is quoted by the same rule
is(wbytes([['a'], [undef]], undef_val => ''), qq{a\n""\n}, "undef_val => '' is quoted alone");
is(wbytes([['a'], [undef]], undef_val => 'NA'), qq{a\nNA\n}, 'undef_val => NA needs no quotes');

# ---- the one-field rule extended to blanks, and the leading '#' --------
is(wbytes({ a => [undef, 'x', '  ', "\t", ' x '] }),
	qq{a\n""\nx\n"  "\n"\t"\n x \n}, 'a lone field of blanks is quoted; one with text is not');
is(wbytes([['a', 'b'], ['#x', 1], ['# y', 2], ['#', 3], ["#\t", 4], ['x#', 5]]),
	qq{a,b\n"#x",1\n"# y",2\n"#",3\n"#\t",4\nx#,5\n},
	"a first field starting with '#' is quoted; a later '#' is not");
is(wbytes([['a', 'b'], ['x', '#y']]), qq{a,b\nx,#y\n}, "'#' in a later field is left bare");
is(wbytes([['#a', 'b'], [1, 2]]), qq{"#a",b\n1,2\n}, "a header starting with '#' is quoted too");
is(wbytes({ '#k' => { v => 1 } }, row_names => 'id'), qq{id,v\n"#k",1\n},
	"a HoH key starting with '#' is the first field, and quoted");
is(wbytes([['a', 'b'], ['#x', 1]], sep => "\t"), qq{a\tb\n"#x"\t1\n}, 'the same for tab-separated');

# The data rows that were lost read back now (the header's '#' is the reader's
# business, and is not tested here)
{
	my $f = path();
	write_table({ a => [undef, 'x', '  ', '#', '# c'] }, $f, quiet => 1);
	is_deeply(read_table($f, output_type => 'aoa'),
		[['a'], [undef], ['x'], ['  '], ['#'], ['# c']],
		'every one-field record reads back, in order');
}

# ---- an AoA's col_names keeps the place of an undef ---------------------
{
	local @W;
	is(wbytes([[1, 2, 3]], col_names => ['a', undef, 'c']), "a,,c\n1,2,3\n",
		'AoA: an undef in col_names is an empty header cell in its place');
	is(scalar @W, 1, 'AoA: ... warned about once, as an unnamed column');
	like($W[0], qr/1 column of '.*' has no name in the header \(the first is column 2\)/,
		'AoA: ... naming column 2');
	@W = ();
	is(wbytes({ a => [1], c => [3] }, col_names => ['a', undef, 'c']), "a,c\n1,3\n",
		'HoA: an undef in col_names names no column, and is skipped');
	is(wbytes([{ a => 1, c => 3 }], col_names => ['a', undef, 'c']), "a,c\n1,3\n",
		'AoH: likewise skipped');
	is(scalar @W, 0, 'HoA/AoH: no warning');
}

# ---- a header cell that is a reference is refused like a data cell -------
throws_ok { wbytes([[[1], 'b'], [1, 2]]) } qr/^write_table: Cannot write nested reference types to table/,
	'AoA header row: a reference dies';
throws_ok { wbytes({ a => [1] }, col_names => [{}]) } qr/^write_table: Cannot write nested reference types to table/,
	'col_names: a reference dies';
throws_ok { wbytes([[1]], col_names => [[]]) } qr/^write_table: Cannot write nested reference types to table/,
	'AoA col_names: a reference dies';

# ---- sep and the file name ---------------------------------------------
throws_ok { wbytes([['a']], sep => '') } qr/\nwrite_table: error: 'sep' must not be empty/, "sep => '' dies";
throws_ok { wbytes([['a']], delim => '') } qr/\nwrite_table: error: 'sep' must not be empty/, "delim => '' dies";
throws_ok { wbytes([['a']], sep => "\0") } qr/\nwrite_table: error: 'sep' may not contain a NUL/, 'a NUL sep dies';
throws_ok { wbytes([['a']], sep => ";\0") } qr/\nwrite_table: error: 'sep' may not contain a NUL/, 'a NUL inside sep dies';
throws_ok { wbytes([['a']], sep => '"') } qr/\nwrite_table: error: 'sep' may not contain '"'/, 'a quote sep dies';
throws_ok { wbytes([['a']], sep => "\r") } qr/\nwrite_table: error: 'sep' may not contain a CR/, 'a CR sep dies';
throws_ok { wbytes([['a']], sep => "\n") } qr/\nwrite_table: error: 'sep' may not contain a LF/, 'a LF sep dies';
throws_ok { wbytes([['a']], sep => undef) } qr/\nwrite_table: error: 'sep' must be a string/, 'sep => undef dies';
throws_ok { wbytes([['a']], sep => qr/,/) } qr/\nwrite_table: error: 'sep' must be a string/, 'a qr// sep dies';
is(wbytes([['a', 'b'], ['x::y', 1]], sep => '::'), qq{a::b\n"x::y"::1\n}, 'a two-byte sep still works');
# ---- a multi-byte sep made by a field's end and the separator after it ---
is(wbytes([['a', 'b'], ['a:', ':b']], sep => '::'), qq{a::b\n"a:":::b\n},
	"sep '::': a field ending in ':' is quoted");
is(wbytes([['a', 'b'], [':b', 'a:']], sep => '::'), qq{a::b\n:b::a:\n},
	"sep '::': ... but not the last field, which no separator follows");
is(wbytes([['a', 'b'], ['xab', 'y']], sep => 'aba'), qq{aabab\n"xab"abay\n},
	"sep 'aba': 'ab' then 'aba' spells 'aba' one byte early");
is(wbytes([['a', 'b'], ['xa', 'y']], sep => 'aba'), qq{aabab\nxaabay\n},
	"sep 'aba': 'a' then 'aba' is 'aaba', which holds 'aba' only where it belongs");
is(wbytes([['h', 'b'], ['xa', 'y']], sep => 'aaa'), qq{haaab\n"xa"aaay\n},
	"sep 'aaa': 'a' then 'aaa' spells it one byte early");
is(wbytes([['h', 'b'], ['xaa', 'y']], sep => 'aaa'), qq{haaab\n"xaa"aaay\n},
	"sep 'aaa': ... and 'aa' then 'aaa' two bytes early");
is(wbytes([['a', 'b'], ['xab', 'y']], sep => 'abab'), qq{aababb\n"xab"ababy\n},
	"sep 'abab': 'ab' then 'abab'");
is(wbytes([['a', 'b'], ['xa', 'by']], sep => 'ab'), qq{aabb\nxaabby\n},
	"sep 'ab': 'a' then 'ab' cannot spell 'ab' early, so stays bare");
is(wbytes([['a', 'b'], ['x:', 'y']], sep => ':;'), qq{a:;b\nx::;y\n},
	"sep ':;': a field ending in ':' is safe, the sep is not periodic");
{
	my $f = path();
	write_table([['h1', 'h2', 'h3'], ['a:', ':b', 'c:'], [':', ':', ':']], $f, sep => '::', quiet => 1);
	is_deeply(read_table($f, sep => '::', output_type => 'aoa'),
		[['h1', 'h2', 'h3'], ['a:', ':b', 'c:'], [':', ':', ':']], "sep '::': the fields read back");
}
{
	my $state = 20261020;	# LCG state: Numerical Recipes' a and c, mod 2**32
	my $rand = sub { $state = (1664525 * $state + 1013904223) % 4294967296; $state % $_[0] };
	my @sep_bytes = (':', ';', 'a', 'b', '|', ',', ' ', "\t", 'x');
	my @cell_bytes = (@sep_bytes, '"', "\n", '#');
	my ($bad, $first) = (0, '');
	for my $t (1 .. 2000) {
		my $sep = join '', map { $sep_bytes[ $rand->(scalar @sep_bytes) ] } 0 .. $rand->(4);
		my $nc = 2 + $rand->(3);
		my @rows = map { [ map { join '', map { $cell_bytes[ $rand->(scalar @cell_bytes) ] } 1 .. $rand->(6) } 1 .. $nc ] } 1 .. 3;
		my @head = map { "c$_" } 1 .. $nc;
		my $f = path('txt');
		write_table([\@head, @rows], $f, sep => $sep, quiet => 1);
		my $got = eval { local $SIG{__WARN__} = sub {}; read_table($f, sep => $sep, output_type => 'aoa') };
		my $want = [\@head, map { [ map { length $_ ? $_ : undef } @$_ ] } @rows];	# '' reads back as undef
		next if $got && Test::More::_deep_check($got, $want);
		$bad++;
		$first ||= "sep " . B::perlstring($sep) . ', rows ' . join(' | ', map { join ' ', map { B::perlstring($_) } @$_ } @rows);
		unlink $f;
	}
	is($bad, 0, '2000 generated tables with a multi-byte or one-byte sep read back as written')
		or diag("the first that did not: $first");
}

{
	# not "nul.csv": NUL is a DOS device name, which -e finds on Windows
	my $f = "$dir/nulbyte.csv";
	throws_ok { write_table([['a']], "$f\0.tex", quiet => 1) }
		qr/\nwrite_table: error: the file name contains a NUL character/, 'a NUL in the file name dies';
	ok(!-e $f, '... and nothing was written under the name before it');
}

# ---- row_names on every shape ------------------------------------------
is(wbytes([['a', 'b'], [1, 2], [3, 4]], row_names => 'id'), "id,a,b\n1,1,2\n2,3,4\n",
	'AoA: a row_names name heads the 1..n labels');
is(wbytes([[1, 2]], col_names => ['a', 'b'], row_names => 'id'), "id,a,b\n1,1,2\n",
	'AoA with col_names: likewise');
is(wbytes({ a => 1, b => 2 }, row_names => 'id'), "id,a,b\n1,1,2\n",
	'flat hash: a row_names name heads the label');
is(wbytes([['a', 'b'], [1, 2]], row_names => 1), ",a,b\n1,1,2\n", 'AoA: row_names => 1 is unchanged');
throws_ok { wbytes([['a', 'b'], [1, 2]], row_names => 'a') }
	qr/^write_table: row_names 'a' collides with an existing column/, 'AoA: a name that is a column dies';
throws_ok { wbytes([[1, 2]], col_names => ['a', 'b'], row_names => 'b') }
	qr/^write_table: row_names 'b' collides with an existing column/, 'AoA col_names: likewise';
throws_ok { wbytes({ a => 1, b => 2 }, row_names => 'b') }
	qr/^write_table: row_names 'b' collides with an existing column/, 'flat hash: likewise';
throws_ok { wbytes({ a => [1, 2] }, row_names => 'nope') }
	qr/^write_table: row_names 'nope' names no column of the hash of arrays/, 'HoA: a missing column dies';
{
	my $f = "$dir/kept.csv";
	write_table([['old']], $f, quiet => 1);
	eval { write_table({ a => [1] }, $f, quiet => 1, row_names => 'nope') };
	is(slurp($f), "old\n", 'HoA: ... before the file is opened');
}
{
	local @W;
	is(wbytes([{ a => 1 }, { a => 2, id => 'L' }, { a => 3 }], row_names => 'id'),
		"id,a\n,1\nL,2\n,3\n", 'AoH: rows without the column get undef_val as their label');
	is(scalar @W, 1, 'AoH: ... and one warning for the file');
	like($W[0], qr/^write_table: 2 rows of '.*' have no 'id' \(row_names\); their label is written as undef_val/,
		'AoH: ... counting them');
	@W = ();
	wbytes([{ a => 1, id => 'x' }], row_names => 'id');
	is(scalar @W, 0, 'AoH: no warning when every row has it');
	@W = ();
	wbytes([{ a => 1 }], row_names => 'id', undef_val => 'NA');
	like($W[0], qr/^write_table: 1 row of '.*' has no 'id' \(row_names\); its label/, 'AoH: singular wording');
}
throws_ok { wbytes([['a'], [1]], row_names => [1]) }
	qr/\nwrite_table: error: 'row_names' must be 0, 1 or a column name, not a reference/, 'row_names => [] dies';

# ---- restricted hashes ---------------------------------------------------
{
	my %r1 = (a => 1, b => 2, gone => 3);
	lock_keys(%r1);
	delete $r1{gone};    # a placeholder stays behind in the buckets
	my %r2 = (a => 3, c => 4);
	lock_keys(%r2);
	is(wbytes([\%r1, \%r2]), "a,b,c\n1,2,\n3,,4\n",
		'AoH of locked rows: absent columns are empty, and the deleted key is no column');
	is(wbytes({ x => \%r1, y => \%r2 }, row_names => 'id'), "id,a,b,c\nx,1,2,\ny,3,,4\n",
		'HoH of locked rows: likewise');
	is(wbytes([\%r1, \%r2], row_names => 'c'), "c,a,b\n,1,2\n4,3,\n", 'AoH: a locked row without the label column');
}

# ---- the header scan: tied rows, UTF-8 keys, and no iterator left -------
{
	tie my %t, 'Tie::StdHash';
	%t = (c => 5, a => 6);
	my %u = ("caf\x{e9}" => 7, "\x{436}" => 8);
	utf8::upgrade(my $cafe = "caf\x{e9}");
	my %v = ($cafe => 9);
	is(wbytes([{ a => 1 }, \%t, \%u, \%v]),
		"a,c,caf\xc3\xa9,\xd0\xb6\n1,,,\n6,5,,\n,,7,8\n,,9,\n",
		'AoH: tied rows and UTF-8 keys are found as before');
	# Here café is only ever a Latin-1 key, and is written as its one byte,
	# where the AoH above met it upgraded too, and the last form seen won: the
	# open question of what encoding write_table writes, unchanged here.
	is(wbytes({ x => { a => 1 }, y => \%t, z => \%u }, row_names => 'id'),
		"id,a,c,caf\xe9,\xd0\xb6\nx,1,,,\ny,6,5,,\nz,,,7,8\n",
		'HoH: likewise');
	# SVf_OOK, the flag of a hash with its iterator allocated: B exports it from
	# 5.12 on, and it is 0x02000000 in sv.h from 5.10.1 to 5.44.0
	my $OOK = defined &B::SVf_OOK ? B::SVf_OOK() : 0x02000000;
	my @rows = map { { a => $_, b => 2 * $_ } } 1 .. 3;
	my %hoh = map { ("r$_" => { a => $_ }) } 1 .. 3;
	wbytes(\@rows);
	wbytes(\%hoh, row_names => 'id');
	is(scalar(grep { B::svref_2object($_)->FLAGS & $OOK } @rows, values %hoh), 0,
		'no row hash of an AoH or a HoH is left with an iterator');
}

# ---- leaks -------------------------------------------------------------
my @leak_aoh = ({ a => 1, b => undef }, { a => '#x', "\x{436}" => 2 });
no_leaks_ok {
	my $f = path();
	eval { write_table(\@leak_aoh, $f, quiet => 1) };
} 'no leaks: AoH header scan and quoting' unless $INC{'Devel/Cover.pm'};
no_leaks_ok {
	my $f = path();
	eval { write_table([['a'], [undef]], $f, quiet => 1, row_names => 'id') };
} 'no leaks: AoA with a named label column' unless $INC{'Devel/Cover.pm'};
no_leaks_ok {
	eval { write_table([['a']], path(), quiet => 1, sep => '"') };
	eval { write_table({ a => [1] }, path(), quiet => 1, row_names => 'nope') };
	eval { write_table([[[1]]], path(), quiet => 1) };
} 'no leaks: the argument croaks' unless $INC{'Devel/Cover.pm'};

done_testing();
