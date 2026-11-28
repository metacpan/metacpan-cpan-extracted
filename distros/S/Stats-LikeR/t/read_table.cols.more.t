#!/usr/bin/env perl
# read_table(..., keep_cols => ..., drop_cols => ...): the cases that
# t/read_table.drop_cols.t and t/read_table.keep_cols.t do not reach.
#
# Found by reading finalize_header() in lib/Stats/LikeR.pm and S_fast_row() /
# S_filter_row() in LikeR.xs against those two files, and by a gcov build run
# over them:
#   - a workbook of several sheets, where each sheet is read with the same
#     selection and a name may be a column of one sheet only;
#   - a read refused for keeping no column, which must still say which name
#     was no column;
#   - S_filter_row()'s "undefined row name" croak with a column left out
#     (LikeR.xs, the hoh branch), which no test executed;
#   - S_fast_row()'s alignment message with a quote note and with a sep note
#     while columns are left out, likewise never executed;
#   - keep_cols on the separators, line ends and quoting that only drop_cols
#     was tried on, and with a filter that writes to, or adds, a field.
# There is no reference implementation for these: each expected table is
# written out here, and every case is read by the parser's plan and by the
# perl row closure (_closure => 1), which must agree.

require 5.010;
use strict;
use warnings FATAL => 'all';
use File::Spec;
use File::Temp 'tempdir';
use Stats::LikeR qw(:all);
use Test::Exception; # throws_ok
use Test::More;
use Test::LeakTrace 'no_leaks_ok';

my $dir = tempdir(CLEANUP => 1);
my $n_file = 0;

# Write $text to a new file with extension $ext, byte for byte.
sub spew {
	my ($ext, $text) = @_;
	my $file = File::Spec->catfile($dir, 'm' . ++$n_file . ".$ext");
	open my $fh, '>:raw', $file or die "$file: $!";
	print {$fh} $text;
	close $fh or die "$file: $!";
	return $file;
}

# One read, by the plan and by the closure: the same table, and the same
# warnings, each matching one of @$warn in order.
sub check_both {
	my ($label, $want, $warn, @args) = @_;
	for my $closure (0, 1) {
		my $how = $closure ? 'closure' : 'plan';
		my @w;
		local $SIG{__WARN__} = sub { push @w, @_ };
		my $got = read_table(@args, _closure => $closure);
		is_deeply($got, $want, "$label, $how");
		ok(@w == @$warn && !grep({ $w[$_] !~ $warn->[$_] } 0 .. $#$warn),
			"$label, $how: " . scalar(@$warn) . ' warning(s)') or diag("warnings: @w");
	}
}

# One read that must die, by both paths: the error, and what was warned first.
sub dies_both {
	my ($label, $re, $warn, @args) = @_;
	for my $closure (0, 1) {
		my $how = $closure ? 'closure' : 'plan';
		my @w;
		local $SIG{__WARN__} = sub { push @w, @_ };
		throws_ok { read_table(@args, _closure => $closure) } $re, "$label, $how";
		ok(@w == @$warn && !grep({ $w[$_] !~ $warn->[$_] } 0 .. $#$warn),
			"$label, $how: " . scalar(@$warn) . ' warning(s) before it') or diag("warnings: @w");
	}
}

#--------
# a workbook of several sheets
#--------
# Each sheet is read with the caller's keep_cols and drop_cols. A name that is
# no column of one of them is an error naming that sheet. Up to 0.3422
# drop_cols warned "not all columns named in 'drop_cols' exist in book.xlsx:
# 'name'" of a workbook that has a column called name, and returned the other
# sheet whole; keep_cols died for keeping no column, without the sheet. A
# pattern may still match no column of a sheet, and 'sheet' reads one alone,
# where an absent name is the warning it is for any single table.
my $book = File::Spec->catfile($dir, 'two.xlsx');
write_table({
	people => [ [qw(NPI name n)], [101, 'bob', 5], [102, 'amy', 6] ],
	sites  => [ [qw(site city)], ['a', 'Boise'], ['b', 'Moscow'] ],
}, $book, quiet => 1);
{
	my %whole = (
		people => [ [qw(NPI name n)], [101, 'bob', 5], [102, 'amy', 6] ],
		sites  => [ [qw(site city)], ['a', 'Boise'], ['b', 'Moscow'] ],
	);
	check_both('two sheets, no selection', \%whole, [], $book, output_type => 'aoa');
	check_both('two sheets, a pattern with a column in each',
		{ people => [ ['NPI'], [101], [102] ], sites => [ ['site'], ['a'], ['b'] ] }, [],
		$book, output_type => 'aoa', keep_cols => qr/^(?:NPI|site)$/);
	check_both('two sheets, a pattern that matches in one',
		{ people => [ ['NPI'], [101], [102] ], sites => $whole{sites} }, [],
		$book, output_type => 'aoa', drop_cols => qr/^n/);
	# A name that is no column of a sheet is an error, for either option, and
	# the error names the sheet: the same names are asked of every sheet, and a
	# sheet read whole under a warning is not what was asked for. Nothing is
	# warned as well.
	my $hint = qr/read_table: pass 'sheet' to read one worksheet, or a qr\/\/ regex, which may match no column of a sheet\n\z/;
	dies_both('two sheets, drop_cols by a name of one sheet',
		qr/\Aread_table: not all columns named in 'drop_cols' exist in \Q$book\E \(sheet "sites"\): 'name'\n$hint/, [],
		$book, output_type => 'aoa', drop_cols => 'name');
	dies_both('two sheets, keep_cols by a name of one sheet',
		qr/\Aread_table: not all columns named in 'keep_cols' exist in \Q$book\E \(sheet "sites"\): 'NPI'\n$hint/, [],
		$book, output_type => 'aoa', keep_cols => 'NPI');
	# a name from each sheet: the first sheet read refuses the other's
	dies_both('two sheets, keep_cols by a name of each',
		qr/\Aread_table: not all columns named in 'keep_cols' exist in \Q$book\E \(sheet "(?:people"\): 'site'|sites"\): 'NPI')\n$hint/, [],
		$book, output_type => 'aoa', keep_cols => [qw(NPI site)]);
	# both options' absent names are in the one error, keep_cols' first
	dies_both('two sheets, absent names in both options',
		qr/\Aread_table: not all columns named in 'keep_cols' exist in \Q$book\E \(sheet "sites"\): 'NPI'\nread_table: not all columns named in 'drop_cols' exist in \Q$book\E \(sheet "sites"\): 'name', 'n'\n$hint/, [],
		$book, output_type => 'aoa', keep_cols => [ 'NPI', qr/./ ], drop_cols => [qw(name n)]);
	# in every shape, and a name beside a pattern that does match is no excuse
	for my $otype (qw(aoh hoa hoh)) {
		dies_both("two sheets, an absent drop_cols name: $otype",
			qr/'drop_cols' exist in \Q$book\E \(sheet "sites"\): 'name'\n$hint/, [],
			$book, output_type => $otype, drop_cols => [ 'name', qr/^city$/ ]);
	}
	# a name that is a column of every sheet is fine
	my $same = File::Spec->catfile($dir, 'same.xlsx');
	write_table({
		y2024 => [ [qw(id v note)], [1, 10, 'a'] ],
		y2025 => [ [qw(id note v)], [2, 'b', 20] ],
	}, $same, quiet => 1);
	check_both('two sheets, names that are columns of both',
		{ y2024 => [ [qw(id v)], [1, 10] ], y2025 => [ [qw(id v)], [2, 20] ] }, [],
		$same, output_type => 'aoa', keep_cols => [qw(id v)]);
	check_both('two sheets, drop_cols by a name of both',
		{ y2024 => [ [qw(id v)], [1, 10] ], y2025 => [ [qw(id v)], [2, 20] ] }, [],
		$same, output_type => 'aoa', drop_cols => 'note');
	# with the sheet chosen there is one table, and no sheet to name
	check_both("sheet => 'people'", [ ['NPI'], [101], [102] ], [],
		$book, output_type => 'aoa', sheet => 'people', keep_cols => 'NPI');
	check_both("sheet => 'people', an absent name", [ ['NPI'], [101], [102] ],
		[ qr/\Aread_table: not all columns named in 'keep_cols' exist in \Q$book\E: 'site'\n\z/ ],
		$book, output_type => 'aoa', sheet => 'people', keep_cols => [qw(NPI site)]);
	# a hoh of each sheet keeps its own first column as the key
	check_both('two sheets as hoh',
		{ people => { 101 => { n => 5 }, 102 => { n => 6 } }, sites => { a => {}, b => {} } }, [],
		$book, output_type => 'hoh', keep_cols => qr/^n$/);
}

#--------
# a read refused for keeping no column says which name was no column
#--------
# A misspelled name is the usual way to keep nothing. Up to 0.3422 the die
# came before the report of the name, so the one read that most needed
# "'Name' is no column" did not get it.
my $abc = spew('csv', "id,name,x,y\n1,bob,p,q\n2,amy,r,s\n");
for my $otype (qw(aoa aoh hoa)) {
	dies_both("a lone misspelled keep_cols name: $otype",
		qr/\Aread_table: 'keep_cols' keeps no column of \Q$abc\E\n\z/,
		[ qr/\Aread_table: not all columns named in 'keep_cols' exist in \Q$abc\E: 'Name'\n\z/ ],
		$abc, output_type => $otype, keep_cols => 'Name');
	dies_both("absent names in both options, nothing left: $otype",
		qr/\Aread_table: 'keep_cols' and 'drop_cols' leave no column of /,
		[ qr/'keep_cols' exist in .*: 'nope'\n\z/, qr/'drop_cols' exist in .*: 'zip'\n\z/ ],
		$abc, output_type => $otype, keep_cols => [qw(x nope)], drop_cols => [qw(x zip)]);
	# a pattern never claimed a column was there, so it adds no warning
	dies_both("a pattern that keeps nothing: $otype",
		qr/\Aread_table: 'keep_cols' keeps no column of /, [],
		$abc, output_type => $otype, keep_cols => qr/^no such column$/);
}
# a hoh keeps its key whatever the name, so the same mistake is a warning there
check_both('a lone misspelled keep_cols name: hoh', { 1 => {}, 2 => {} },
	[ qr/'keep_cols' exist in \Q$abc\E: 'Name'\n\z/ ],
	$abc, output_type => 'hoh', keep_cols => 'Name');

#--------
# a hoh's undefined row name, with a filter and a column left out
#--------
# The filter path has its own croak for it (S_filter_row() in LikeR.xs). Row 1
# is read by the closure on some header forms, so the empty name is on row 3.
{
	my $f = spew('csv', "id,x,y\n1,a,b\n2,c,d\n,e,f\n");
	for my $sel ([ drop_cols => 'x' ], [ keep_cols => 'y' ], [ keep_cols => qr/./, drop_cols => qr/^x$/ ]) {
		dies_both("undefined row name under a filter, @$sel[0]",
			qr/\Aread_table: undefined row name \(column 'id'\) in \Q$f\E data row 3\n\z/, [],
			$f, output_type => 'hoh', @$sel, filter => sub { 1 });
		dies_both("undefined row name under a keyed filter, @$sel[0]",
			qr/\Aread_table: undefined row name \(column 'id'\) in \Q$f\E data row 3\n\z/, [],
			$f, output_type => 'hoh', @$sel, filter => { x => sub { 1 } });
		# a filter that drops that row leaves nothing to refuse
		check_both("a filter dropping the unnamed row, @$sel[0]", { 1 => { y => 'b' }, 2 => { y => 'd' } }, [],
			$f, output_type => 'hoh', @$sel, filter => sub { length $_[0][0] });
	}
}

#--------
# the alignment message's notes, with columns left out
#--------
{
	# a quoted field that runs across lines and takes the row's last
	# separator with it: the row is a field short, and the message says where
	# the quote opened
	my $q = spew('csv', qq{id,a,b\n1,x,y\n2,"never\nclosed,z\n3,p,q\n});
	for my $otype (qw(aoa aoh hoa hoh)) {
		my @msg;
		for my $closure (0, 1) {
			local $SIG{__WARN__} = sub { };
			eval { read_table($q, output_type => $otype, drop_cols => 'a', _closure => $closure); 1 }
				and fail("a row misaligned by a quote is refused: $otype, closure $closure");
			push @msg, $@;
		}
		like($msg[0], qr/\AAlignment error on \Q$q\E data row 2 \(\d+ fields vs 3 headers\); .*quot/s,
			"a row misaligned by a quote, a column left out: $otype");
		is($msg[0], $msg[1], "and the plan and the closure say it in the same words: $otype");
	}
	# one column, and a later row with a separator in it: the sep note
	my $one = spew('csv', "id\n1\n2\n3;4,5\n");
	for my $sel ([ keep_cols => 'id' ], [ drop_cols => 'nope' ], [ keep_cols => qr/./, drop_cols => qr/^zz/ ]) {
		my @msg;
		for my $closure (0, 1) {
			local $SIG{__WARN__} = sub { };
			eval { read_table($one, output_type => 'aoa', @$sel, _closure => $closure); 1 }
				and fail("a row wider than a one-column header is refused, closure $closure");
			push @msg, $@;
		}
		like($msg[0], qr/\AAlignment error on \Q$one\E data row 3 \(2 fields vs 1 headers\); the header has no ',' in it/,
			"the sep note, @$sel[0]");
		is($msg[0], $msg[1], "in the same words by both paths, @$sel[0]");
	}
	# and with a column really left out of a two-column file, where a wide row
	# gets cells for the fields past the header before it is refused
	my $two = spew('csv', "id,a\n1,2\n3,4,5,6\n");
	dies_both('a wide row, a column left out',
		qr/\AAlignment error on \Q$two\E data row 2 \(4 fields vs 2 headers\)\.\n\z/, [],
		$two, output_type => 'aoa', drop_cols => 'a');
}

#--------
# keep_cols on what only drop_cols was tried on
#--------
{
	my @hdr  = qw(id b d);
	my @rows = ( [1, 'x', 'z'], [2, undef, 'w'] );
	my %want = (
		aoa => [ [ @hdr ], map { [ @$_ ] } @rows ],
		aoh => [ map { my $r = $_; +{ map { $hdr[$_] => $r->[$_] } 0 .. 2 } } @rows ],
		hoa => { id => [1, 2], b => ['x', undef], d => [qw(z w)] },
		hoh => { 1 => { b => 'x', d => 'z' }, 2 => { b => undef, d => 'w' } },
	);
	my @keep = (keep_cols => [ 'd', qr/^(?:id|b)$/ ]);
	my %file = (
		'a regex sep'     => [ spew('txt', "id ; a;b ;c; d\n1;p ; x;q;z\n2;;;;w\n"), sep => qr/\s*;\s*/ ],
		'CR line ends'    => [ spew('csv', "id,a,b,c,d\r1,p,x,q,z\r2,,,,w\r") ],
		'blank and comment lines' => [ spew('csv', "# a note\nid,a,b,c,d\n\n1,p,x,q,z\n# another\n2,,,,w\n") ],
		'a commented-out header, marker hugging' => [ spew('csv', "#id,a,b,c,d\n1,p,x,q,z\n2,,,,w\n") ],
	);
	for my $what (sort keys %file) {
		for my $otype (qw(aoa aoh hoa hoh)) {
			check_both("keep_cols, $what: $otype", $want{$otype}, [],
				@{ $file{$what} }, output_type => $otype, @keep);
		}
	}
	# whitespace-separated: leading and trailing blanks make no field
	my $ws = spew('txt', "id a  b\tc d\n  1 p x  q z  \n2 n n n w\n");
	check_both('keep_cols, a whitespace sep', [ [qw(id b d)], [1, 'x', 'z'], [2, 'n', 'w'] ], [],
		$ws, sep => qr/\s+/, output_type => 'aoa', @keep);
	# quote => '': a '"' is text, in a kept field and in one that is not
	my $nq = spew('csv', qq{id,drop,keep\n1,"a,b"\n2,c,"d\n});
	check_both("keep_cols, quote => ''", [ [qw(id keep)], [1, 'b"'], [2, '"d'] ], [],
		$nq, quote => '', output_type => 'aoa', keep_cols => [qw(id keep)]);
	# header => 0, with a class list by the file's own fields: the third is
	# not kept, so its 'x' is never asked to be a number
	my $h0 = spew('csv', "1,a,2.5\n2,b,x\n");
	check_both('keep_cols, header => 0 and a colClasses list', [ [qw(V1 V2)], [1, 'a'], [2, 'b'] ], [],
		$h0, header => 0, output_type => 'aoa', keep_cols => [qw(V1 V2)],
		colClasses => [qw(integer character numeric)]);
	dies_both('the same list, the third kept',
		qr/colClasses makes column 'V3' \(field 3\) numeric, but data row 2 of .* has 'x' there/, [],
		$h0, header => 0, output_type => 'aoa', keep_cols => qr/^V/,
		colClasses => [qw(integer character numeric)]);
	# auto_row_names: the synthesized column keys a hoh without being named
	my $t = spew('tsv', "a\tb\tc\nr1\t1\t2\t3\nr2\t4\t5\t6\n");
	check_both('keep_cols, auto_row_names, a hoh keyed by the unnamed column',
		{ r1 => { c => 3 }, r2 => { c => 6 } }, [],
		$t, auto_row_names => 1, output_type => 'hoh', keep_cols => 'c');
	check_both('keep_cols, auto_row_names with its own name',
		{ r1 => { a => 1 }, r2 => { a => 4 } }, [],
		$t, auto_row_names => 'gene', output_type => 'hoh', keep_cols => [qw(gene a)]);
}

#--------
# keep_cols and a filter that writes
#--------
{
	my $f = spew('csv', "id,x,y,z\n1,a,b,c\n2,d,e,f\n");
	for my $otype (qw(aoa aoh hoa hoh)) {
		# what a filter writes to a field that is not kept reaches the row, where
		# the next filter reads it, and not the table
		my %want = (
			aoa => [ [qw(id z)], [1, 'c'], [2, 'f'] ],
			aoh => [ { id => 1, z => 'c' }, { id => 2, z => 'f' } ],
			hoa => { id => [1, 2], z => [qw(c f)] },
			hoh => { 1 => { z => 'c' }, 2 => { z => 'f' } },
		);
		for my $closure (0, 1) {
			my @seen;
			my $got = read_table($f, output_type => $otype, keep_cols => [qw(id z)], _closure => $closure,
				filter => {
					2 => sub { $_ = 'zz'; 1 },
					3 => sub { push @seen, $_[0][1] . (exists $_{x} ? '!' : ''); 1 },
				});
			is_deeply($got, $want{$otype}, "a write to a field not kept: $otype, closure $closure");
			is_deeply(\@seen, [qw(zz zz)], "reaches the row only: $otype, closure $closure");
		}
		# a filter on a kept column still changes what is stored
		my %up = (
			aoa => [ [qw(id z)], [1, 'C'], [2, 'F'] ],
			aoh => [ { id => 1, z => 'C' }, { id => 2, z => 'F' } ],
			hoa => { id => [1, 2], z => [qw(C F)] },
			hoh => { 1 => { z => 'C' }, 2 => { z => 'F' } },
		);
		check_both("a filter rewriting a kept column: $otype", $up{$otype}, [],
			$f, output_type => $otype, keep_cols => [qw(id z)], filter => { z => sub { $_ = uc; 1 } });
	}
	# a field a filter adds is no column of the file: neither option can leave
	# it out, and one a filter removes is simply not there
	check_both('a field a filter added, keep_cols',
		[ [qw(id z)], [1, 'c', 'extra'], [2, 'f', 'extra'] ], [],
		$f, output_type => 'aoa', keep_cols => [qw(id z)], filter => sub { push @{ $_[0] }, 'extra'; 1 });
	check_both('a field a filter removed, keep_cols', [ [qw(id z)], [1], [2] ], [],
		$f, output_type => 'aoa', keep_cols => [qw(id z)], filter => sub { pop @{ $_[0] }; 1 });
	check_both('a field a filter removed, drop_cols', [ [qw(id y z)], [1, 'b'], [2, 'e'] ], [],
		$f, output_type => 'aoa', drop_cols => 'x', filter => sub { pop @{ $_[0] }; 1 });
}

#--------
# leaks
#--------
# Everything a block needs is made out here: see t/read_table.drop_cols.t.
my $rx_n     = qr/^n$/;
my @one_each = qw(NPI site);
my $flt_all  = sub { 1 };
my $quiet    = sub { };
my $unnamed  = spew('csv', "id,x,y\n1,a,b\n2,c,d\n,e,f\n");
unless ($INC{'Devel/Cover.pm'}) {
	for my $otype (qw(aoa aoh hoa hoh)) {
		no_leaks_ok {
			eval { read_table($book, output_type => $otype, keep_cols => $rx_n) }
		} "read_table(keep_cols) on two sheets: no memory leaks, $otype";
		no_leaks_ok {
			eval { read_table($book, output_type => $otype, keep_cols => \@one_each) }
		} "read_table(keep_cols) refusing the first sheet for a name: no memory leaks, $otype";
		no_leaks_ok {
			eval { read_table($book, output_type => $otype, keep_cols => 'NPI') }
		} "read_table(keep_cols) refusing the second sheet for a name: no memory leaks, $otype";
		no_leaks_ok {
			eval { read_table($book, output_type => $otype, drop_cols => 'name') }
		} "read_table(drop_cols) refusing the second sheet for a name: no memory leaks, $otype";
		no_leaks_ok {
			local $SIG{__WARN__} = $quiet;
			eval { read_table($abc, output_type => $otype, keep_cols => 'Name') }
		} "read_table(keep_cols) by a misspelled name: no memory leaks, $otype";
	}
	no_leaks_ok {
		eval { read_table($unnamed, output_type => 'hoh', drop_cols => 'x', filter => $flt_all) }
	} 'read_table(drop_cols, filter) croaking on an undefined row name: no memory leaks';
}

# A header that repeats a name keeps the last field of that name, and
# colClasses is not applied to the earlier one, which the table never holds:
# up to 0.3422 the CSV parser converted it anyway and croaked on its value,
# where an .xlsx and the perl closure read the same table.  An aoa keeps every
# field, so it is still converted, and still refused, there.
{
	my $file = spew('csv', "e,b,e\nx,2,3\n");
	my @cls = (colClasses => [ 'integer', 'character', 'integer' ]);
	local $SIG{__WARN__} = sub { die @_ unless $_[0] =~ /duplicate column name/ };
	for my $closure (0, 1) {
		my @c = $closure ? (_closure => 1) : ();
		my $how = $closure ? 'closure' : 'plan';
		is_deeply(read_table($file, @cls, @c), [ { e => 3, b => '2' } ],
			"read_table: colClasses skips a field a repeated name shadows (aoh, $how)");
		is_deeply(read_table($file, @cls, @c, output_type => 'hoa'), { e => [3], b => ['2'] },
			"read_table: likewise for a hoa ($how)");
		is_deeply(read_table($file, @cls, @c, output_type => 'hoh', row_names => 'b'), { 2 => { e => 3 } },
			"read_table: likewise for a hoh ($how)");
		throws_ok { read_table($file, @cls, @c, output_type => 'aoa') } qr/colClasses makes column 'e' \(field 1\) integer/,
			"read_table: an aoa keeps the field, so colClasses still refuses it ($how)";
	}
}

# A quoted field in a dropped column is scanned to its end but not gathered,
# and an .xlsx cell in a dropped column is not built (S_field_dropped()).  The
# quote must still be followed exactly: doubled quotes, a separator and line
# ends inside it, a quote opened after text, and one never closed.  A row whose
# only value is in a dropped .xlsx column is still a row, not a blank one.
{
	my $q = spew('csv', qq{a,b,c\n1,"x ""y"", z",3\n4,"two\nlines\r\nthree",6\n7,pre"open, still"post,9\n10,"",12\n});
	my $want = [ { a => 1, c => 3 }, { a => 4, c => 6 }, { a => 7, c => 9 }, { a => 10, c => 12 } ];
	check_both('a dropped quoted column', $want, [], $q, drop_cols => 'b');
	check_both('a quoted column keep_cols leaves out', $want, [], $q, keep_cols => [qw(a c)]);
	check_both('a dropped quoted column, aoa',
		[ [qw(a c)], [1, 3], [4, 6], [7, 9], [10, 12] ], [], $q, drop_cols => 'b', output_type => 'aoa');
	# a quote in a dropped column that runs to the end of the file still swallows
	# the rows after it: the row comes up short, and both are said
	my $open = spew('csv', qq{a,b,c\n1,"never closed,3\n4,5,6\n});
	dies_both('a dropped quoted column never closed', qr/Alignment error .* \(2 fields vs 3 headers\); a '"' at the start of a field on line 2/,
		[ qr/end of file inside a quoted field/ ], $open, drop_cols => 'b');
	# a dropped quoted field on a row that is too long is still in the message
	my $long = spew('csv', qq{a,b,c\n1,"two\nlines",3,4\n});
	dies_both('a dropped quoted field on a long row', qr/4 fields/, [], $long, drop_cols => 'b');

	my $x = File::Spec->catfile($dir, 'dropped_only.xlsx');
	write_table([ [qw(a b c)], [1, 2, 3], [undef, 'only b', undef], [4, undef, 6] ], $x, quiet => 1);
	check_both('an .xlsx row whose only value is in a dropped column is kept',
		[ { a => 1, c => 3 }, { a => undef, c => undef }, { a => 4, c => 6 } ], [], $x, drop_cols => 'b');
	check_both('likewise as an aoa', [ [qw(a c)], [1, 3], [undef, undef], [4, 6] ], [], $x, drop_cols => 'b', output_type => 'aoa');
	check_both('likewise with keep_cols', { a => [1, undef, 4] }, [], $x, keep_cols => 'a', output_type => 'hoa');
}

done_testing();
