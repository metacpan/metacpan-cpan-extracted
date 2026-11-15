#!/usr/bin/env perl
# read_table(..., drop_cols => ...): columns left out of the table by name,
# given as whole names, as qr// patterns, or as a list of either.
#
# Provenance. These cases are written for this module; none is taken from R's
# or pandas' test suites. The nearest references are R's
# read.table(colClasses = "NULL"), which skips a column by position or name,
# and pandas' read_csv(usecols = <callable>), which keeps the columns a
# predicate on the name accepts; neither takes a regex, and neither leaves a
# column out of the memory it reads into, so there is no reference output to
# freeze. R 4.6.1's tests/reg-tests-2.R has two read.table() calls with a
# "NULL" class (lines 1355 and 1358), both by position, which is not a form
# this option has. What the references do settle:
#   - what an empty pattern matches, which is every name. R 4.6.2:
#     grepl("", c("NPI", "name", "bob")) is TRUE TRUE TRUE, and R 4.6.1's
#     tests/reg-tests-1b.R ("zero-length patterns in gregexpr") pins
#     gregexpr("", "abc") matching at each of its three positions; pandas
#     3.0.4: pd.Index(["NPI", "name", "bob"]).str.contains("") is
#     [True, True, True]. So drop_cols => qr// is every column, which is the
#     "empty pattern" block;
#   - what a name that is no column does, which is warn and read on. R 4.6.1
#     src/library/utils/R/readtable.R, read.table(): a name in colClasses that
#     match() does not find in col.names gives
#     warning("not all columns named in 'colClasses' exist"), and the columns
#     that were found are still classed. The "columns by name" block holds
#     drop_cols to the same, in the same words.
# What every other case is held to instead:
#   - a table written out in full in this file, in all four output types;
#   - the perl row closure (_closure => 1), which builds the same table without
#     the parser's plan, so the two implementations check each other;
#   - a plain read with the columns dropped afterwards, on a 600 x 40 table;
#   - for a name, the anchored pattern that says the same thing.
# Nothing here is floating point, so there is no tolerance to justify.

require 5.010;
use strict;
use warnings FATAL => 'all';
use File::Spec;
use File::Temp 'tempdir';
use IO::Compress::Gzip '$GzipError';
use Stats::LikeR;
use Test::Exception; # throws_ok, lives_ok
use Test::More;
use Test::LeakTrace 'no_leaks_ok';

my $dir = tempdir(CLEANUP => 1);
my $n_file = 0;

# Write $text to a new file with extension $ext, byte for byte.
sub spew {
	my ($ext, $text) = @_;
	my $file = File::Spec->catfile($dir, 'f' . ++$n_file . ".$ext");
	open my $fh, '>:raw', $file or die "$file: $!";
	print {$fh} $text;
	close $fh or die "$file: $!";
	return $file;
}

# The four output types of one table, from its header and its rows.
sub shapes {
	my ($hdr, $rows, $rn) = @_;
	$rn = $hdr->[0] unless defined $rn;
	my ($k) = grep { $hdr->[$_] eq $rn } 0 .. $#$hdr;
	my %s;
	$s{aoa} = [ [ @$hdr ], map { [ @$_ ] } @$rows ];
	$s{aoh} = [ map {
		my $r = $_;
		+{ map { $hdr->[$_] => $r->[$_] } 0 .. $#$hdr }
	} @$rows ];
	$s{hoa} = @$rows ? { map {
		my $c = $_;
		$hdr->[$c] => [ map { $_->[$c] } @$rows ]
	} 0 .. $#$hdr } : {};
	$s{hoh} = { map {
		my $r = $_;
		$r->[$k] => +{ map { $hdr->[$_] => $r->[$_] } grep { $_ != $k } 0 .. $#$hdr }
	} @$rows };
	return \%s;
}

# read_table, with what it warned.
sub read_w {
	my @w;
	local $SIG{__WARN__} = sub { push @w, @_ };
	my $t = read_table(@_);
	return ($t, \@w);
}

# One table, in every output type, by the parser's plan and by the closure.
# $warn is a regex each read must warn with, once, or undef for silence.
sub check_all {
	my ($label, $file, $hdr, $rows, $args, $warn) = @_;
	my $want = shapes($hdr, $rows);
	for my $otype (qw(aoa aoh hoa hoh)) {
		for my $closure (0, 1) {
			my $how = $closure ? 'closure' : 'plan';
			# a hoh is keyed by the table's first column, named outright: the
			# default is the file's first column, which a case may leave out
			my ($got, $w) = read_w($file, output_type => $otype, @$args,
				_closure => $closure, $otype eq 'hoh' ? (row_names => $hdr->[0]) : ());
			is_deeply($got, $want->{$otype}, "$label: $otype, $how");
			if (defined $warn) {
				ok(@$w == 1 && $w->[0] =~ $warn, "$label: $otype, $how warns")
					or diag("warnings: @$w");
			} else {
				is(scalar @$w, 0, "$label: $otype, $how is silent")
					or diag("warnings: @$w");
			}
		}
	}
}

# Both paths must refuse the read in the same words.
sub dies_all {
	my ($label, $file, $re, $args, $otypes) = @_;
	for my $otype (@{ $otypes || [qw(aoa aoh hoa hoh)] }) {
		for my $closure (0, 1) {
			my $how = $closure ? 'closure' : 'plan';
			throws_ok {
				local $SIG{__WARN__} = sub { };
				read_table($file, output_type => $otype, @$args, _closure => $closure)
			} $re, "$label: $otype, $how";
		}
	}
}

#--------
# the case in the request: NPPES-style license columns
#--------
my $npi = spew('csv', join "\n",
	'NPI,Provider License Number_1,Provider Last Name,Provider License Number State Code_1,Entity Type Code,provider license number_2,score',
	'1003000126,MD-0481,ENKESHAFI,MD,1,x9,1.50',
	'1003000134,,CIBULL,IL,1,,2.0',
	'1003000142,35.0921,KHALIL,OH,2,NA,3e1',
	'');
my $rx_lic = qr/^Provider License Number/;
my @npi_hdr = ('NPI', 'Provider Last Name', 'Entity Type Code', 'provider license number_2', 'score');
my @npi_rows = (
	[1003000126, 'ENKESHAFI', 1, 'x9',  '1.50'],
	[1003000134, 'CIBULL',    1, undef, '2.0'],
	[1003000142, 'KHALIL',    2, 'NA',  '3e1'],
);
check_all('license columns', $npi, \@npi_hdr, \@npi_rows, [ drop_cols => $rx_lic ]);

# the default output type, with nothing else given
is_deeply(read_table($npi, drop_cols => $rx_lic), shapes(\@npi_hdr, \@npi_rows)->{aoh},
	'default output_type is an aoh without the columns');

# /i reaches the lower-case column too; the pattern itself is case-sensitive
check_all('case-insensitive pattern', $npi,
	[ @npi_hdr[0, 1, 2, 4] ], [ map { [ @{$_}[0, 1, 2, 4] ] } @npi_rows ],
	[ drop_cols => qr/^provider license number/i ]);

# a list of patterns: a column goes when any of them matches
check_all('list of patterns', $npi,
	[ @npi_hdr[0, 1] ], [ map { [ @{$_}[0, 1] ] } @npi_rows ],
	[ drop_cols => [ $rx_lic, qr/Code\z/, qr/^provider/, qr/^score$/ ] ]);

# not anchored unless it says so: the same two columns, matched mid-name
check_all('unanchored pattern', $npi, \@npi_hdr, \@npi_rows, [ drop_cols => qr/License Number/ ]);

# a pattern that matches no column, and undef: the table as it is without
# the option
{
	my @all_hdr = ('NPI', 'Provider License Number_1', 'Provider Last Name',
		'Provider License Number State Code_1', 'Entity Type Code',
		'provider license number_2', 'score');
	my @all_rows = (
		[1003000126, 'MD-0481', 'ENKESHAFI', 'MD', 1, 'x9',  '1.50'],
		[1003000134, undef,     'CIBULL',    'IL', 1, undef, '2.0'],
		[1003000142, '35.0921', 'KHALIL',    'OH', 2, 'NA',  '3e1'],
	);
	check_all('pattern matching nothing', $npi, \@all_hdr, \@all_rows,
		[ drop_cols => qr/^no such column$/ ]);
	check_all('drop_cols => undef', $npi, \@all_hdr, \@all_rows, [ drop_cols => undef ]);
	check_all('na_strings beside drop_cols', $npi,
		[ @npi_hdr ], [ @npi_rows[0, 1], [1003000142, 'KHALIL', 2, undef, '3e1'] ],
		[ drop_cols => $rx_lic, na_strings => 'NA' ]);
}

#--------
# columns by name
#--------
# A plain string is a whole column name: compared with eq, so it is anchored
# at both ends, case-sensitive, and its regex metacharacters are text.
{
	my @hdr4  = @npi_hdr[0, 1, 2, 4];
	my @rows4 = map { [ @{$_}[0, 1, 2, 4] ] } @npi_rows;
	check_all('one name', $npi,
		[ 'NPI', 'Provider License Number_1', @npi_hdr[1, 2, 3, 4] ],
		[ [1003000126, 'MD-0481', 'ENKESHAFI', 1, 'x9',  '1.50'],
		  [1003000134, undef,     'CIBULL',    1, undef, '2.0'],
		  [1003000142, '35.0921', 'KHALIL',    2, 'NA',  '3e1'] ],
		[ drop_cols => 'Provider License Number State Code_1' ]);
	check_all('a list of names', $npi, \@npi_hdr, \@npi_rows,
		[ drop_cols => [ 'Provider License Number_1', 'Provider License Number State Code_1' ] ]);
	check_all('a list of one name', $npi,
		[ 'NPI', 'Provider License Number_1', 'Provider Last Name',
		  'Provider License Number State Code_1', 'Entity Type Code', 'provider license number_2' ],
		[ [1003000126, 'MD-0481', 'ENKESHAFI', 'MD', 1, 'x9'],
		  [1003000134, undef,     'CIBULL',    'IL', 1, undef],
		  [1003000142, '35.0921', 'KHALIL',    'OH', 2, 'NA'] ],
		[ drop_cols => ['score'] ]);
	# names and patterns in one list, in either order
	check_all('names and a pattern', $npi, \@hdr4, \@rows4,
		[ drop_cols => [ 'provider license number_2', $rx_lic ] ]);
	check_all('a pattern and names', $npi, [ @npi_hdr[0, 1] ], [ map { [ @{$_}[0, 1] ] } @npi_rows ],
		[ drop_cols => [ $rx_lic, 'score', qr/Code\z/, 'provider license number_2' ] ]);
	# a name a pattern also matches, and a name given twice: once is enough
	check_all('a name a pattern also matches', $npi, \@npi_hdr, \@npi_rows,
		[ drop_cols => [ 'Provider License Number_1', $rx_lic, 'Provider License Number_1' ] ]);
	# a name says what the anchored, quoted pattern says
	for my $name ('score', 'Entity Type Code', 'NPI') {
		for my $otype (qw(aoa aoh hoa)) {
			is_deeply(read_table($npi, output_type => $otype, drop_cols => $name),
				read_table($npi, output_type => $otype, drop_cols => qr/\A\Q$name\E\z/),
				"'$name' is qr/\\A\\Q$name\\E\\z/: $otype");
		}
	}
}

# A name is the whole name, in its own case. One that is no column is warned
# about, as R's read.table() warns of a colClasses name (see the provenance
# above), and the read goes on with the names that are.
{
	my @all_hdr = ('NPI', 'Provider License Number_1', 'Provider Last Name',
		'Provider License Number State Code_1', 'Entity Type Code',
		'provider license number_2', 'score');
	my @all_rows = (
		[1003000126, 'MD-0481', 'ENKESHAFI', 'MD', 1, 'x9',  '1.50'],
		[1003000134, undef,     'CIBULL',    'IL', 1, undef, '2.0'],
		[1003000142, '35.0921', 'KHALIL',    'OH', 2, 'NA',  '3e1'],
	);
	my $absent = sub {
		my $list = join ', ', map { "'$_'" } @_;
		return qr/\Aread_table: not all columns named in 'drop_cols' exist in \Q$npi\E: \Q$list\E\n\z/;
	};
	check_all('a name is not a prefix', $npi, \@all_hdr, \@all_rows,
		[ drop_cols => 'Provider License Number' ], $absent->('Provider License Number'));
	check_all('a name is not a suffix', $npi, \@all_hdr, \@all_rows,
		[ drop_cols => 'Code' ], $absent->('Code'));
	check_all('a name is case-sensitive', $npi, \@all_hdr, \@all_rows,
		[ drop_cols => 'npi' ], $absent->('npi'));
	check_all('a name is not a pattern', $npi, \@all_hdr, \@all_rows,
		[ drop_cols => '^score$' ], $absent->('^score$'));
	check_all('an empty name where no column has one', $npi, \@all_hdr, \@all_rows,
		[ drop_cols => '' ], $absent->(''));
	# a number is a name too, never a field position
	check_all('a number is a name, not a position', $npi, \@all_hdr, \@all_rows,
		[ drop_cols => 2 ], $absent->('2'));
	# the names that are columns still go; the absent ones are listed once
	# each, in the order given, in one warning
	check_all('absent names beside present ones', $npi,
		[ @all_hdr[0 .. 5] ], [ map { [ @{$_}[0 .. 5] ] } @all_rows ],
		[ drop_cols => [ 'zip', 'score', 'nope', 'zip' ] ], $absent->('zip', 'nope'));
	# a pattern that matches nothing is still silent beside a name that is found
	check_all('a silent pattern beside a name', $npi,
		[ @all_hdr[0 .. 5] ], [ map { [ @{$_}[0 .. 5] ] } @all_rows ],
		[ drop_cols => [ qr/^no such column$/, 'score' ] ]);
	# a name a pattern would have covered is still reported when it is absent
	check_all('an absent name beside a pattern', $npi, \@npi_hdr, \@npi_rows,
		[ drop_cols => [ $rx_lic, 'Provider License Number_9' ] ],
		$absent->('Provider License Number_9'));
}

# regex metacharacters in a name are the characters they are
{
	my $f = spew('csv', "id,a.b,axb,cost (\$),x|y,a+\n1,2,3,4,5,6\n7,8,9,10,11,12\n");
	check_all('a dot in a name', $f, [ 'id', 'axb', 'cost ($)', 'x|y', 'a+' ],
		[ [1, 3, 4, 5, 6], [7, 9, 10, 11, 12] ], [ drop_cols => 'a.b' ]);
	check_all('brackets, a bar and a plus in names', $f, [qw(id a.b axb)],
		[ [1, 2, 3], [7, 8, 9] ], [ drop_cols => [ 'cost ($)', 'x|y', 'a+' ] ]);
}

# names that are numbers, and the empty name
{
	my $f = spew('csv', "id,0,2,10,2.0\na,b,c,d,e\nf,g,h,i,j\n");
	check_all('a column named 0', $f, [qw(id 2 10 2.0)], [ [qw(a c d e)], [qw(f h i j)] ],
		[ drop_cols => 0 ]);
	check_all('columns named by numbers', $f, [qw(id 0 2.0)], [ [qw(a b e)], [qw(f g j)] ],
		[ drop_cols => [ 2, 10 ] ]);
	# 2.0 the number is the name "2"; the column "2.0" takes the string
	check_all("'2.0' the string", $f, [qw(id 0 2 10)], [ [qw(a b c d)], [qw(f g h i)] ],
		[ drop_cols => '2.0' ]);
	# a merged banner row repeats the empty name: '' leaves every one out
	my $g = spew('csv', "id,,x,,\n1,a,b,c,d\n2,e,f,g,h\n");
	check_all('the empty name, repeated', $g, [qw(id x)], [ [1, 'b'], [2, 'f'] ],
		[ drop_cols => '' ]);
}

# the names a name is compared with are the ones a pattern sees
{
	check_all('col_names, by name', $npi,
		[qw(id last type)],
		[ [1003000126, 'ENKESHAFI', 1], [1003000134, 'CIBULL', 1], [1003000142, 'KHALIL', 2] ],
		[ col_names => [qw(id lic1 last st1 type lic2 score)], drop_cols => [qw(lic1 st1 lic2 score)] ]);
	# the header's own name is gone once col_names has renamed it
	my ($got, $w) = read_w($npi, col_names => [qw(id lic1 last st1 type lic2 score)],
		drop_cols => 'NPI', output_type => 'aoa');
	is_deeply($got->[0], [qw(id lic1 last st1 type lic2 score)], 'a renamed column keeps under its old name');
	ok(@$w == 1 && $w->[0] =~ /not all columns named in 'drop_cols' exist in .*: 'NPI'\n\z/,
		'and the old name is reported') or diag("warnings: @$w");
	my $f = spew('csv', "a,b,c,d\ne,f,g,h\n");
	check_all('header => 0, by name', $f, [qw(V1 V3)], [ [qw(a c)], [qw(e g)] ],
		[ header => 0, drop_cols => [qw(V2 V4)] ]);
	my $t = spew('tsv', "a\tb\tc\nr1\t1\t2\t3\nr2\t4\t5\t6\n");
	check_all('auto_row_names, by name', $t, [qw(row_name c)], [ ['r1', 3], ['r2', 6] ],
		[ auto_row_names => 1, drop_cols => [qw(a b)] ]);
	($got, $w) = read_w($t, auto_row_names => 1, drop_cols => 'row_name', output_type => 'aoh');
	is_deeply($got, [ { a => 1, b => 2, c => 3 }, { a => 4, b => 5, c => 6 } ],
		'auto_row_names: the row-name column excluded by name');
	is(scalar @$w, 0, 'and silently');
	my $e = spew('csv', ",x,y\nr1,1,2\nr2,3,4\n");
	($got, $w) = read_w($e, drop_cols => 'row_name', output_type => 'aoa');
	is_deeply($got, [ [qw(x y)], [1, 2], [3, 4] ], 'an empty first name excluded as row_name');
	is(scalar @$w, 0, 'and silently');
	my $c = spew('csv', "# id,val,note\n1,2,three\n4,5,six\n");
	check_all('commented-out header, by name', $c, [qw(id note)], [ [1, 'three'], [4, 'six'] ],
		[ drop_cols => 'val' ]);
}

# UTF-8 names: a name held as bytes and one held as characters both match
{
	my $f = spew('csv', "id,Gr\xc3\xb6\xc3\x9fe,na\xe2\x80\x94me\n1,180,x\n2,175,y\n");
	my $dash  = "na\xe2\x80\x94me";
	my $groes = "Gr\xc3\xb6\xc3\x9fe";
	check_all('UTF-8 name, as bytes', $f, [ 'id', $dash ], [ [1, 'x'], [2, 'y'] ],
		[ drop_cols => $groes ]);
	# characters perl holds as Latin-1, with no UTF8 flag
	check_all('UTF-8 name, as characters', $f, [ 'id', $dash ], [ [1, 'x'], [2, 'y'] ],
		[ drop_cols => "Gr\x{f6}\x{df}e" ]);
	# the same characters with the flag on
	my $up = "Gr\x{f6}\x{df}e";
	utf8::upgrade($up);
	check_all('UTF-8 name, as upgraded characters', $f, [ 'id', $dash ], [ [1, 'x'], [2, 'y'] ],
		[ drop_cols => $up ]);
	check_all('UTF-8 name with a wide character', $f, [ 'id', $groes ], [ [1, 180], [2, 175] ],
		[ drop_cols => "na\x{2014}me" ]);
	check_all('UTF-8 names, one of each kind', $f, ['id'], [ [1], [2] ],
		[ drop_cols => [ "na\x{2014}me", $groes ] ]);
	# the same name given as bytes and as characters is found either way, and
	# neither is reported
	check_all('UTF-8 name given both ways', $f, [ 'id', $dash ], [ [1, 'x'], [2, 'y'] ],
		[ drop_cols => [ $groes, "Gr\x{f6}\x{df}e" ] ]);
	# an absent wide name is reported as the UTF-8 it would be in the file
	my ($got, $w) = read_w($f, drop_cols => "nope\x{2014}", output_type => 'aoa');
	is(scalar @{ $got->[0] }, 3, 'an absent wide name leaves the table whole');
	ok(@$w == 1 && $w->[0] =~ /exist in .*: 'nope\xe2\x80\x94'\n\z/ && !utf8::is_utf8($w->[0]),
		'and is reported as bytes') or diag("warnings: @$w");
	# bytes that are not UTF-8 are compared as the bytes they are
	my $g = spew('csv', "id,Gr\xf6\xdfe\n1,180\n");
	check_all('Latin-1 name', $g, ['id'], [ [1] ], [ drop_cols => "Gr\xf6\xdfe" ]);
}

# repeated names, the row_names column, filters and colClasses, by name
{
	my $f = spew('csv', "id,x,y,x,z\n1,a,b,c,d\n2,e,f,g,h\n");
	check_all('repeated name excluded by name', $f, [qw(id y z)], [ [1, 'b', 'd'], [2, 'f', 'h'] ],
		[ drop_cols => 'x' ]);
	my $r = spew('csv', "id,name,x,y\n1,bob,p,q\n2,amy,r,s\n");
	dies_all('row_names column excluded by name', $r,
		qr/\Aread_table: 'drop_cols' leaves out "name", the row_names column of /,
		[ row_names => 'name', drop_cols => 'name' ], ['hoh']);
	dies_all('default row_names column excluded by name', $r,
		qr/\Aread_table: 'drop_cols' leaves out "id", the row_names column of /,
		[ drop_cols => ['id'] ], ['hoh']);
	dies_all('every column excluded by name', $r,
		qr/\Aread_table: 'drop_cols' leaves out every column of /,
		[ drop_cols => [qw(id name x y)] ]);
	dies_all('every column excluded by names and a pattern', $r,
		qr/\Aread_table: 'drop_cols' leaves out every column of /,
		[ drop_cols => [ 'id', qr/^[xy]$/, 'name' ] ]);
	check_all('filter keyed on a column excluded by name', $npi, \@npi_hdr, [ $npi_rows[1] ],
		[ drop_cols => [ 'Provider License Number_1', 'Provider License Number State Code_1' ],
		  filter => { 'Provider License Number State Code_1' => sub { defined $_ && $_ eq 'IL' } } ]);
	check_all('colClasses naming a column excluded by name', $npi, \@npi_hdr,
		[ [1003000126, 'ENKESHAFI', 1, 'x9', 1.5], [1003000134, 'CIBULL', 1, undef, 2],
		  [1003000142, 'KHALIL', 2, 'NA', 30] ],
		[ drop_cols => [ 'Provider License Number_1', 'Provider License Number State Code_1' ],
		  colClasses => { score => 'numeric', 'Provider License Number_1' => 'numeric' } ]);
}

# .xlsx, .gz and a VCF's own columns
{
	my $x = File::Spec->catfile($dir, 'names.xlsx');
	my $groes = "Gr\xc3\xb6\xc3\x9fe";	# the bytes a sheet's name comes back as
	write_table([
		[ 'NPI', 'Provider License Number_1', 'name', $groes, 'n' ],
		[ 101, 'A1', 'bob', 180, 5 ],
		[ 102, undef, 'amy', 175, undef ],
	], $x, quiet => 1);
	is(read_table($x, output_type => 'aoa')->[0][3], $groes, '.xlsx: the UTF-8 name is read back as its bytes');
	check_all('.xlsx, by name', $x, [qw(NPI name n)], [ [101, 'bob', 5], [102, 'amy', undef] ],
		[ drop_cols => [ 'Provider License Number_1', $groes ] ]);
	check_all('.xlsx, by a name of characters', $x, [ 'NPI', 'Provider License Number_1', 'name', 'n' ],
		[ [101, 'A1', 'bob', 5], [102, undef, 'amy', undef] ],
		[ drop_cols => "Gr\x{f6}\x{df}e" ]);
	check_all('.xlsx, an absent name', $x, [ 'NPI', 'Provider License Number_1', 'name', $groes ],
		[ [101, 'A1', 'bob', 180], [102, undef, 'amy', 175] ],
		[ drop_cols => [ 'n', 'N' ] ], qr/not all columns named in 'drop_cols' exist in .*: 'N'\n\z/);
	my $gz = File::Spec->catfile($dir, 'names.csv.gz');
	my $text = "id,a,b,c,d\n1,p,x,q,z\n2,,,,w\n";
	IO::Compress::Gzip::gzip(\$text => $gz) or die "gzip: $GzipError";
	check_all('gzip-compressed, by name', $gz, [qw(id b d)], [ [1, 'x', 'z'], [2, undef, 'w'] ],
		[ drop_cols => [qw(a c)] ]);
	my $v = spew('vcf', join "\n",
		'##fileformat=VCFv4.2',
		"#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT\tS1",
		"chr1\t100\trs1\tA\tG\t50\tPASS\tDP=10\tGT:DP\t0/1:10",
		"chr2\t200\t.\tC\tT\t60\tPASS\tDP=20\tGT:DP\t1/1:20",
		'');
	# the "#" is off the first name by the time the names are compared
	check_all('VCF, explode => 0, by name', $v, [qw(POS REF ALT S1)],
		[ [100, 'A', 'G', '0/1:10'], [200, 'C', 'T', '1/1:20'] ],
		[ explode => 0, drop_cols => [qw(CHROM ID QUAL FILTER INFO FORMAT)] ]);
	for my $args ([], [ explode => 1 ]) {
		throws_ok { read_table($v, @$args, drop_cols => 'INFO') }
			qr/read_table: error: 'drop_cols' cannot be used with an exploded VCF; pass explode => 0/,
			'exploded VCF refuses a name' . (@$args ? ', explode => 1' : ', by default');
	}
}

#--------
# which names the patterns see
#--------
# col_names renames a header's columns first
check_all('col_names with a header', $npi,
	[qw(id last type)],
	[ [1003000126, 'ENKESHAFI', 1], [1003000134, 'CIBULL', 1], [1003000142, 'KHALIL', 2] ],
	[ col_names => [qw(id lic1 last st1 type lic2 score)], drop_cols => qr/^(?:lic|st)\d|^score$/ ]);

# header => 0: V1, V2, ...
{
	my $f = spew('csv', "a,b,c,d\ne,f,g,h\n");
	check_all('header => 0', $f, [qw(V1 V3)], [ [qw(a c)], [qw(e g)] ],
		[ header => 0, drop_cols => qr/^V[24]$/ ]);
	check_all('header => 0 with col_names', $f, [qw(w y)], [ [qw(a c)], [qw(e g)] ],
		[ header => 0, col_names => [qw(w x y z)], drop_cols => qr/^[xz]$/ ]);
}

# auto_row_names: the synthesized column is a name like any other, and the
# first data row, which fixes the header, goes through the closure
{
	my $f = spew('tsv', "a\tb\tc\nr1\t1\t2\t3\nr2\t4\t5\t6\nr3\t7\t8\t9\n");
	check_all('auto_row_names, a data column excluded', $f,
		[qw(row_name a c)], [ ['r1', 1, 3], ['r2', 4, 6], ['r3', 7, 9] ],
		[ auto_row_names => 1, drop_cols => qr/^b$/ ]);
	check_all('auto_row_names, its own name', $f,
		[qw(gene c)], [ ['r1', 3], ['r2', 6], ['r3', 9] ],
		[ auto_row_names => 'gene', drop_cols => qr/^[ab]$/ ]);
	my ($got, $w) = read_w($f, auto_row_names => 1, drop_cols => qr/^row_name$/,
		output_type => 'aoh');
	is_deeply($got, [ { a => 1, b => 2, c => 3 }, { a => 4, b => 5, c => 6 },
		{ a => 7, b => 8, c => 9 } ], 'auto_row_names: the row-name column itself excluded');
}

# an empty first header name is read as row_name, and is matched as that
{
	my $f = spew('csv', ",x,y\nr1,1,2\nr2,3,4\n");
	check_all('empty first name', $f, [qw(row_name y)], [ ['r1', 2], ['r2', 4] ],
		[ drop_cols => qr/^x$/ ]);
	my ($got) = read_w($f, drop_cols => qr/^row_name$/, output_type => 'aoa');
	is_deeply($got, [ [qw(x y)], [1, 2], [3, 4] ], 'empty first name excluded as row_name');
}

# a commented-out header, in both of its spellings
{
	my $f = spew('csv', "# id,val,note\n1,2,three\n4,5,six\n");
	check_all('commented-out header', $f, [qw(id note)], [ [1, 'three'], [4, 'six'] ],
		[ drop_cols => qr/^val$/ ]);
	my $g = spew('csv', "#id,val,note\n1,2,three\n4,5,six\n");
	check_all('commented-out header, marker hugging', $g, [qw(id note)],
		[ [1, 'three'], [4, 'six'] ], [ drop_cols => qr/^val$/ ]);
}

# UTF-8 names: a pattern of bytes and a pattern of characters both match
{
	my $f = spew('csv', "id,Gr\xc3\xb6\xc3\x9fe,na\xe2\x80\x94me\n1,180,x\n2,175,y\n");
	my $dash = "na\xe2\x80\x94me";
	check_all('UTF-8 name, pattern of bytes', $f, [ 'id', $dash ], [ [1, 'x'], [2, 'y'] ],
		[ drop_cols => qr/^Gr\xc3\xb6\xc3\x9fe$/ ]);
	check_all('UTF-8 name, pattern of characters', $f, [ 'id', $dash ], [ [1, 'x'], [2, 'y'] ],
		[ drop_cols => qr/^Gr\x{f6}\x{df}e$/ ]);
	check_all('UTF-8 name, wide character in the pattern', $f,
		[ 'id', "Gr\xc3\xb6\xc3\x9fe" ], [ [1, 180], [2, 175] ],
		[ drop_cols => qr/\x{2014}/ ]);
	# bytes that are not UTF-8 are matched as the bytes they are
	my $g = spew('csv', "id,Gr\xf6\xdfe\n1,180\n");
	check_all('Latin-1 name', $g, ['id'], [ [1] ], [ drop_cols => qr/^Gr\xf6\xdfe$/ ]);
}

#--------
# repeated header names
#--------
{
	my $f = spew('csv', "id,x,y,x,z\n1,a,b,c,d\n2,e,f,g,h\n");
	# every field carrying an excluded name goes, and nothing is warned
	# about: no value was lost to "later values win"
	check_all('repeated name excluded', $f, [qw(id y z)], [ [1, 'b', 'd'], [2, 'f', 'h'] ],
		[ drop_cols => qr/^x$/ ]);
	# a repeated name that is kept still resolves to its last field, and
	# still warns (an aoa keeps both fields, and never warned)
	my $warn = qr/duplicate column name\(s\) in .* \(later values win\): 'x' x 2 \(fields 2, 4\)/;
	for my $otype (qw(aoh hoa hoh)) {
		for my $closure (0, 1) {
			my ($got, $w) = read_w($f, output_type => $otype, drop_cols => qr/^[yz]$/,
				_closure => $closure);
			is_deeply($got, shapes([qw(id x)], [ [1, 'c'], [2, 'g'] ])->{$otype},
				"repeated name kept: $otype, closure $closure");
			ok(@$w == 1 && $w->[0] =~ $warn, "repeated name kept: $otype, closure $closure warns")
				or diag("warnings: @$w");
		}
	}
	for my $closure (0, 1) {
		my ($got, $w) = read_w($f, output_type => 'aoa', drop_cols => qr/^[yz]$/,
			_closure => $closure);
		is_deeply($got, [ [qw(id x x)], [1, 'a', 'c'], [2, 'e', 'g'] ],
			"repeated name kept: aoa keeps both fields, closure $closure");
		is(scalar @$w, 0, "repeated name kept: aoa is silent, closure $closure");
	}
}

#--------
# what the parser has to cut around: quotes, separators, line ends
#--------
{
	# quoted fields, doubled quotes and a line break, in excluded and kept columns
	my $f = spew('csv', join '',
		qq{id,drop1,keep,drop2\n},
		qq{1,"a,b","c ""d"" e","x\ny"\n},
		qq{2,"","f,g",plain\n},
		qq{3,p,"h\ni","q ""r"""\n});
	check_all('quoted fields', $f, [qw(id keep)],
		[ [1, 'c "d" e'], [2, 'f,g'], [3, "h\ni"] ], [ drop_cols => qr/^drop/ ]);
	check_all('quoted fields, first and last kept', $f, [qw(id drop2)],
		[ [1, "x\ny"], [2, 'plain'], [3, 'q "r"'] ], [ drop_cols => qr/^(?:drop1|keep)$/ ]);
	check_all('first column excluded', $f, [qw(keep drop2)],
		[ ['c "d" e', "x\ny"], ['f,g', 'plain'], ["h\ni", 'q "r"'] ],
		[ drop_cols => qr/^(?:id|drop1)$/ ]);

	# the file ends inside a quoted field of an excluded column: warned
	# about as ever, and the row is kept
	my $g = spew('csv', qq{id,drop\n1,a\n2,"never closed\n});
	check_all('EOF inside an excluded quoted field', $g, ['id'], [ [1], [2] ],
		[ drop_cols => qr/^drop$/ ], qr/end of file inside a quoted field/);

	# quote => '': a '"' is text
	my $h = spew('csv', qq{id,drop,keep\n1,"a,b"\n2,c,"d\n});
	check_all("quote => ''", $h, [qw(id keep)], [ [1, 'b"'], [2, '"d'] ],
		[ quote => '', drop_cols => qr/^drop$/ ]);
}
{
	my @hdr  = qw(id b d);
	my @rows = ( [1, 'x', 'z'], [2, undef, 'w'] );
	my $args = [ drop_cols => qr/^[ac]$/ ];
	check_all('tab-separated by its name', spew('tsv', "id\ta\tb\tc\td\n1\tp\tx\tq\tz\n2\t\t\t\tw\n"),
		\@hdr, \@rows, $args);
	check_all('literal multi-byte sep', spew('txt', "id::a::b::c::d\n1::p::x::q::z\n2::::::::w\n"),
		\@hdr, \@rows, [ @$args, sep => '::' ]);
	check_all('regex sep', spew('txt', "id ; a;b ;c; d\n1;p ; x;q;z\n2;;;;w\n"),
		\@hdr, \@rows, [ @$args, sep => qr/\s*;\s*/ ]);
	check_all('whitespace sep', spew('txt', "id a  b\tc d\n  1 p x  q z  \n2 n n n w\n"),
		\@hdr, [ [1, 'x', 'z'], [2, 'n', 'w'] ], [ @$args, sep => qr/\s+/ ]);
	check_all('CRLF line ends', spew('csv', "id,a,b,c,d\r\n1,p,x,q,z\r\n2,,,,w\r\n"),
		\@hdr, \@rows, $args);
	check_all('CR line ends', spew('csv', "id,a,b,c,d\r1,p,x,q,z\r2,,,,w\r"),
		\@hdr, \@rows, $args);
	check_all('byte-order mark and no final newline',
		spew('csv', "\xEF\xBB\xBFid,a,b,c,d\n1,p,x,q,z\n2,,,,w"), \@hdr, \@rows, $args);
	check_all('blank and comment lines', spew('csv', "# a note\nid,a,b,c,d\n\n1,p,x,q,z\n# another\n2,,,,w\n"),
		\@hdr, \@rows, $args);

	my $gz = File::Spec->catfile($dir, 'packed.csv.gz');
	my $text = "id,a,b,c,d\n1,p,x,q,z\n2,,,,w\n";
	IO::Compress::Gzip::gzip(\$text => $gz) or die "gzip: $GzipError";
	check_all('gzip-compressed', $gz, \@hdr, \@rows, $args);
}

# a header with no data rows
{
	my $f = spew('csv', "id,a,b\n");
	check_all('header only', $f, [qw(id b)], [], [ drop_cols => qr/^a$/ ]);
}

# one column left
{
	my $f = spew('csv', "id,a,b\n1,2,3\n4,5,6\n");
	check_all('one column left', $f, ['id'], [ [1], [4] ], [ drop_cols => qr/^[ab]$/ ]);
}

#--------
# row_names
#--------
{
	my $f = spew('csv', "id,name,x,y\n1,bob,p,q\n2,amy,r,s\n");
	for my $closure (0, 1) {
		my ($got, $w) = read_w($f, output_type => 'hoh', row_names => 'name',
			drop_cols => qr/^x$/, _closure => $closure);
		is_deeply($got, { bob => { id => 1, y => 'q' }, amy => { id => 2, y => 's' } },
			"hoh keyed by a kept column, closure $closure");
		is(scalar @$w, 0, "hoh keyed by a kept column is silent, closure $closure");
		# only the row-names column is left: the rows are there, and empty
		($got) = read_w($f, output_type => 'hoh', drop_cols => qr/^(?:name|x|y)$/,
			_closure => $closure);
		is_deeply($got, { 1 => {}, 2 => {} }, "hoh with only its key left, closure $closure");
	}
	dies_all('explicit row_names column excluded', $f,
		qr/\Aread_table: 'drop_cols' leaves out "name", the row_names column of /,
		[ row_names => 'name', drop_cols => qr/^na/ ], ['hoh']);
	dies_all('default row_names column excluded', $f,
		qr/\Aread_table: 'drop_cols' leaves out "id", the row_names column of /,
		[ drop_cols => qr/^id$/ ], ['hoh']);
	# a repeated row name, with an excluded column: warned about once, as ever
	my $g = spew('csv', "id,x,y\n1,a,b\n1,c,d\n");
	for my $closure (0, 1) {
		my ($got, $w) = read_w($g, output_type => 'hoh', drop_cols => qr/^x$/,
			_closure => $closure);
		is_deeply($got, { 1 => { y => 'd' } }, "repeated row name, closure $closure");
		ok(@$w == 1 && $w->[0] =~ /duplicate row name '1'/, "repeated row name warns, closure $closure")
			or diag("warnings: @$w");
	}
	# an empty row name is still refused
	my $h = spew('csv', "id,x,y\n1,a,b\n,c,d\n");
	dies_all('undefined row name', $h, qr/read_table: undefined row name \(column 'id'\) in .* data row 2/,
		[ drop_cols => qr/^x$/ ], ['hoh']);
}

#--------
# colClasses
#--------
{
	# a class naming an excluded column is not applied: 'MD-0481' is no number,
	# and the column is not read
	my @cls_rows = (
		[1003000126, 'ENKESHAFI', 1, 'x9',  1.5],
		[1003000134, 'CIBULL',    1, undef, 2],
		[1003000142, 'KHALIL',    2, 'NA',  30],
	);
	check_all('colClasses by name', $npi, \@npi_hdr, \@cls_rows,
		[ drop_cols => $rx_lic, colClasses => { NPI => 'integer', score => 'numeric',
			'Provider License Number_1' => 'numeric' } ]);
	dies_all('the same class without drop_cols', $npi,
		qr/read_table: colClasses makes column 'Provider License Number_1' \(field 2\) numeric, but data row 1 of .* has 'MD-0481' there/,
		[ colClasses => { 'Provider License Number_1' => 'numeric' } ]);
	# a list is by the file's own fields, excluded ones included
	check_all('colClasses by position', $npi, \@npi_hdr, \@cls_rows,
		[ drop_cols => $rx_lic, colClasses => [ 'integer', 'numeric', 'character',
			'integer', 'integer', 'character', 'numeric' ] ]);
	# one class for every column, and the same for an excluded one
	my @txt_rows = map { [ map { defined $_ ? "$_" : undef } @$_ ] } @npi_rows;
	check_all("colClasses => 'character'", $npi, \@npi_hdr, \@txt_rows,
		[ drop_cols => $rx_lic, colClasses => 'character' ]);
	# a kept column that fails its class is refused, with the field numbered
	# as the file has it and the row as the file has it
	dies_all('colClasses failure in a kept column', $npi,
		qr/read_table: colClasses makes column 'provider license number_2' \(field 6\) integer, but data row 1 of .* has 'x9' there/,
		[ drop_cols => $rx_lic, colClasses => { 'provider license number_2' => 'integer' } ]);
	my $late = spew('csv', "id,drop,v\n1,a,10\n2,b,20\n3,c,x\n");
	dies_all('colClasses failure on a later row', $late,
		qr/read_table: colClasses makes column 'v' \(field 3\) integer, but data row 3 of .* has 'x' there/,
		[ drop_cols => qr/^drop$/, colClasses => { v => 'integer' } ]);
	# a name in the hash that is no column is still warned about
	check_all('colClasses naming no column', $npi, \@npi_hdr, \@npi_rows,
		[ drop_cols => $rx_lic, colClasses => { nope => 'integer' } ],
		qr/not all columns named in 'colClasses' exist/);
}

#--------
# filter
#--------
{
	# a whole-row filter is handed every field of the file, and %_ (and $_[1])
	# without the excluded names
	for my $closure (0, 1) {
		my (@widths, @has_excl, @has_kept, @same);
		my ($got) = read_w($npi, output_type => 'aoh', drop_cols => $rx_lic, _closure => $closure,
			filter => sub {
				push @widths, scalar @{ $_[0] };
				push @has_excl, exists $_{'Provider License Number_1'} ? 1 : 0;
				push @has_kept, exists $_{NPI} && exists $_[1]{score} ? 1 : 0;
				push @same, $_ == $_[0] ? 1 : 0;
				return $_[0][3] ne 'IL';	# an excluded field, by position
			});
		is_deeply($got, shapes(\@npi_hdr, [ @npi_rows[0, 2] ])->{aoh},
			"whole-row filter on an excluded field, closure $closure");
		is_deeply(\@widths, [7, 7, 7], "the filter's row has every field, closure $closure");
		is_deeply(\@has_excl, [0, 0, 0], "%_ lacks an excluded column, closure $closure");
		is_deeply(\@has_kept, [1, 1, 1], "%_ has the kept columns, closure $closure");
		is_deeply(\@same, [1, 1, 1], "\$_ is the row for key 0, closure $closure");
	}
	# keyed on an excluded column, by its name and by its field number
	check_all('filter keyed on an excluded name', $npi, \@npi_hdr, [ $npi_rows[1] ],
		[ drop_cols => $rx_lic,
		  filter => { 'Provider License Number State Code_1' => sub { defined $_ && $_ eq 'IL' } } ]);
	check_all('filter keyed on an excluded field number', $npi, \@npi_hdr, [ @npi_rows[0, 2] ],
		[ drop_cols => $rx_lic, filter => { 2 => sub { defined $_ } } ]);
	# what a filter writes to an excluded field goes back into the row, where a
	# later filter reads it, and nowhere else
	for my $otype (qw(aoa aoh hoa hoh)) {
		for my $closure (0, 1) {
			my @seen;
			my ($got) = read_w($npi, output_type => $otype, drop_cols => $rx_lic,
				_closure => $closure, filter => {
					2 => sub { $_ = 'zz'; 1 },
					4 => sub {
						push @seen, $_[0][1] . (exists $_[1]{'Provider License Number_1'} ? '!' : '');
						1
					},
				});
			is_deeply($got, shapes(\@npi_hdr, \@npi_rows)->{$otype},
				"write to an excluded field: $otype, closure $closure");
			is_deeply(\@seen, [qw(zz zz zz)],
				"write to an excluded field reaches the row only: $otype, closure $closure");
		}
	}
	# a filter on a kept column still changes what is stored
	check_all('filter rewriting a kept column', $npi, \@npi_hdr,
		[ map { my @r = @$_; $r[1] = lc $r[1]; \@r } @npi_rows[0, 1] ],
		[ drop_cols => $rx_lic, filter => {
			'Provider Last Name' => sub { $_ = lc; 1 },
			'Entity Type Code'   => sub { $_ == 1 },
		} ]);
	# with colClasses, a filter and drop_cols together
	check_all('filter, colClasses and drop_cols', $npi, \@npi_hdr,
		[ [1003000134, 'CIBULL', 1, undef, 2], [1003000142, 'KHALIL', 2, 'NA', 30] ],
		[ drop_cols => $rx_lic, colClasses => { score => 'numeric' },
		  filter => { score => sub { $_ >= 2 } } ]);
	dies_all('filter, then a colClasses failure', $npi,
		qr/colClasses makes column 'score' \(field 7\) integer, but data row 3 of .* has '3e1' there/,
		[ drop_cols => $rx_lic, colClasses => { score => 'integer' },
		  filter => { NPI => sub { $_ > 1003000134 } } ]);
	# a filter that keeps the row it was handed: an aoa row is a copy, without
	# the excluded fields, and the kept row has all of them
	for my $closure (0, 1) {
		my @kept;
		my ($got) = read_w($npi, output_type => 'aoa', drop_cols => $rx_lic,
			_closure => $closure, filter => sub { push @kept, $_[0]; 1 });
		is_deeply($got, shapes(\@npi_hdr, \@npi_rows)->{aoa},
			"filter keeping its row, closure $closure");
		is(scalar @{ $kept[1] }, 7, "the row a filter kept is whole, closure $closure");
		is($kept[2][1], '35.0921', "and holds the excluded field, closure $closure");
	}
	# a filter that makes its row longer: the added field is no column of the
	# file, so no pattern can leave it out
	for my $closure (0, 1) {
		my ($got) = read_w($npi, output_type => 'aoa', drop_cols => $rx_lic,
			_closure => $closure, filter => sub { push @{ $_[0] }, 'extra'; 1 });
		is_deeply($got->[1], [1003000126, 'ENKESHAFI', 1, 'x9', '1.50', 'extra'],
			"a field a filter added is kept, closure $closure");
	}
	# a filter key that names no column is still refused, excluded or not
	dies_all('unknown filter column', $npi, qr/Filter column 'nope' not found in the header/,
		[ drop_cols => $rx_lic, filter => { nope => sub { 1 } } ]);
}

#--------
# ragged rows: the width is the file's, not the table's
#--------
{
	my $short = spew('csv', "id,a,b,c\n1,2,3,4\n5,6\n");
	dies_all('short row', $short, qr/\AAlignment error on .* data row 2 \(2 fields vs 4 headers\)\.$/,
		[ drop_cols => qr/^[ab]$/ ]);
	my $long = spew('csv', "id,a,b,c\n1,2,3,4\n5,6,7,8,9,10\n");
	dies_all('long row', $long, qr/\AAlignment error on .* data row 2 \(6 fields vs 4 headers\)\.$/,
		[ drop_cols => qr/^[ab]$/ ]);
	dies_all('long row, last column excluded', $long,
		qr/\AAlignment error on .* data row 2 \(6 fields vs 4 headers\)\.$/,
		[ drop_cols => qr/^c$/ ]);
}

#--------
# a wider table: the plan against the closure, and against dropping the
# columns after a plain read
#--------
{
	my @hdr = ('id', map { "x$_" } 1 .. 39);
	my @site = qw(north south east west);
	my $text = join(',', @hdr) . "\n";
	for my $r (1 .. 600) {
		$text .= join(',', "r$r", map {
			my $c = $_;
			  ($r + $c) % 11 == 0 ? ''
			: $c % 5 == 0         ? $site[ ($r * $c) % 4 ]	# a category: shared cells
			: $c % 5 == 1         ? $r * $c			# an integer
			: $c % 5 == 2         ? sprintf('%.2f', $r / $c)
			: $c % 5 == 3         ? ($r % 7 ? "v$r.$c" : 'NA')
			:                       qq{"q,$r"}
		} 1 .. 39) . "\n";
	}
	my $f = spew('csv', $text);
	my $plain = read_table($f, output_type => 'aoa', na_strings => 'NA');
	is(scalar @$plain, 601, 'wide table: 600 rows and a header');
	for my $rx (qr/^x\d*[02468]$/, qr/^x(?:[1-9]|[12]\d|3[0-8])$/, qr/^x39$/, qr/^x1$/) {
		my @keep = grep { $plain->[0][$_] !~ $rx } 0 .. $#hdr;
		my @rows = map { [ @{$_}[@keep] ] } @{$plain}[1 .. $#$plain];
		my $want = shapes([ @hdr[@keep] ], \@rows);
		for my $otype (qw(aoa aoh hoa hoh)) {
			for my $closure (0, 1) {
				my $got = read_table($f, output_type => $otype, drop_cols => $rx,
					na_strings => 'NA', _closure => $closure);
				is_deeply($got, $want->{$otype},
					"wide table, $rx: $otype, closure $closure, " . scalar(@keep) . ' columns kept');
			}
		}
		# an aoa's rows are as wide as what is kept, not as the file
		my $aoa = read_table($f, output_type => 'aoa', drop_cols => $rx);
		is(scalar(grep { @$_ != @keep } @$aoa), 0, "wide table, $rx: every aoa row has " . scalar(@keep) . ' cells');
	}
}

#--------
# .xlsx
#--------
{
	my $x = File::Spec->catfile($dir, 'book.xlsx');
	write_table([
		[ 'NPI', 'Provider License Number_1', 'name', 'Provider License Number_2', 'n' ],
		[ 101, 'A1', 'bob', 'B1', 5 ],
		[ 102, undef, 'amy', 'B2', undef ],
		[ 103, 'A3', undef, undef, 7 ],
	], $x, quiet => 1);
	my @hdr  = qw(NPI name n);
	my @rows = ( [101, 'bob', 5], [102, 'amy', undef], [103, undef, 7] );
	check_all('.xlsx', $x, \@hdr, \@rows, [ drop_cols => $rx_lic ]);
	check_all('.xlsx, colClasses naming an excluded column', $x, \@hdr, \@rows,
		[ drop_cols => $rx_lic, colClasses => { 'Provider License Number_1' => 'integer', n => 'numeric' } ]);
	check_all('.xlsx with a filter on an excluded column', $x, \@hdr, [ @rows[0, 2] ],
		[ drop_cols => $rx_lic, filter => { 'Provider License Number_1' => sub { defined $_ } } ]);
	dies_all('.xlsx, every column excluded', $x, qr/'drop_cols' leaves out every column of /,
		[ drop_cols => qr// ]);
}

#--------
# the empty pattern
#--------
# An empty pattern matches every name (see the provenance above), so every
# column is left out and the read is refused. Before perl 5.18 the match
# operator does not match an empty qr// as it is written: it reuses the last
# pattern that matched successfully in the scope it is called from, and until
# 0.3422 read_table handed it the caller's qr// as it came. That failed the
# .xlsx case above on perl 5.10.1, 5.12.5 and 5.16.3, where the pattern left
# over from the reader's own matching happened to match no header, and left a
# delimited file's result to whatever the caller had matched last. Each read
# here therefore follows a successful match of /b/, which is in exactly one of
# the three names, so that an old perl without the fix leaves out "bob" alone
# and returns. The patterns are compiled out here for the leak checks below.
my $rx_empty   = qr//;
my $rx_empty_i = qr//i;
my $rx_empty_x = qr//x;
my $rx_nope    = qr/^no such column$/;
my $csv3 = spew('csv', "NPI,name,bob\n1,amy,2\n3,joe,4\n");
my $tsv3 = spew('tsv', "NPI\tname\tbob\n1\tamy\t2\n3\tjoe\t4\n");
my $xl3  = File::Spec->catfile($dir, 'empty.rx.xlsx');
write_table([ [qw(NPI name bob)], [1, 'amy', 2], [3, 'joe', 4] ], $xl3, quiet => 1);
for my $f ([ '.csv', $csv3 ], [ '.tsv', $tsv3 ], [ '.xlsx', $xl3 ]) {
	my ($ext, $file) = @$f;
	for my $c ([ 'qr//', $rx_empty ], [ 'qr//i', $rx_empty_i ], [ 'qr//x', $rx_empty_x ],
			[ '[qr//]', [ $rx_empty ] ], [ '[no match, qr//]', [ $rx_nope, $rx_empty ] ]) {
		my ($what, $drop) = @$c;
		for my $otype (qw(aoa aoh hoa hoh)) {
			for my $closure (0, 1) {
				my $how = $closure ? 'closure' : 'plan';
				throws_ok {
					local $SIG{__WARN__} = sub { };
					'abc' =~ /b/ or die 'the match that arms the old perls failed';
					read_table($file, output_type => $otype, drop_cols => $drop,
						_closure => $closure)
				} qr/'drop_cols' leaves out every column of /,
					"$ext, drop_cols => $what is every column: $otype, $how";
			}
		}
	}
}
# and a pattern that is not empty is still its own after such a match
{
	'abc' =~ /b/ or die 'the match that arms the old perls failed';
	check_all('.csv, a pattern after an unrelated match', $csv3, [qw(NPI bob)],
		[ [1, 2], [3, 4] ], [ drop_cols => qr/^name$/ ]);
}

#--------
# VCF
#--------
{
	my $v = spew('vcf', join "\n",
		'##fileformat=VCFv4.2',
		'##source=test',
		"#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT\tS1",
		"chr1\t100\trs1\tA\tG\t50\tPASS\tDP=10\tGT:DP\t0/1:10",
		"chr2\t200\t.\tC\tT\t60\tPASS\tDP=20\tGT:DP\t1/1:20",
		'');
	# the "#" is off the first name by the time the patterns are tried
	check_all('VCF, explode => 0', $v, [qw(POS REF ALT S1)],
		[ [100, 'A', 'G', '0/1:10'], [200, 'C', 'T', '1/1:20'] ],
		[ explode => 0, drop_cols => [ qr/^CHROM$/, qr/^(?:ID|QUAL|FILTER|INFO|FORMAT)$/ ] ]);
	for my $args ([], [ explode => 1 ]) {
		throws_ok { read_table($v, @$args, drop_cols => qr/^INFO$/) }
			qr/read_table: error: 'drop_cols' cannot be used with an exploded VCF; pass explode => 0/,
			'exploded VCF refuses drop_cols' . (@$args ? ', explode => 1' : ', by default');
	}
	lives_ok { read_table($v, header => 0, drop_cols => qr/^V[89]$/) }
		'VCF with header => 0 is not exploded, and takes drop_cols';
}

#--------
# refused arguments
#--------
{
	my $re = qr/read_table: error: 'drop_cols' must be a column name, a qr\/\/ regex, or an ARRAY reference of them/;
	my $rx = qr/a/;
	my %bad = (
		'an empty list'           => [],
		'a list with an undef'    => [ $rx, undef ],
		'a list of one undef'     => [ undef ],
		'a name and an undef'     => [ 'NPI', undef ],
		'a list with a list'      => [ [ $rx ] ],
		'a list of a list of names' => [ ['NPI'] ],
		'a name and a hash reference' => [ 'NPI', { score => 1 } ],
		'a hash reference'        => { a => 1 },
		'a scalar reference'      => \'a',
		'a code reference'        => sub { 1 },
	);
	for my $what (sort keys %bad) {
		throws_ok { read_table($npi, drop_cols => $bad{$what}) } $re, "drop_cols refuses $what";
	}
	dies_all('every column excluded', $npi,
		qr/\Aread_table: 'drop_cols' leaves out every column of /, [ drop_cols => qr/./ ]);
	dies_all('every column excluded, by a list', $npi,
		qr/\Aread_table: 'drop_cols' leaves out every column of /,
		[ drop_cols => [ qr/^[Pp]rovider/, qr/^(?:NPI|score)$/, qr/Code/ ] ]);
	my $hdr_only = spew('csv', "a,b\n");
	dies_all('every column of a header-only file excluded', $hdr_only,
		qr/\Aread_table: 'drop_cols' leaves out every column of /, [ drop_cols => qr/^[ab]$/ ]);
	# the singular spelling is not this option
	throws_ok { read_table($npi, drop_col => $rx) } qr/unknown argument\(s\): drop_col/,
		"'drop_col' is an unknown argument";
}

#--------
# the caller's patterns and data are left alone
#--------
{
	my @list = ($rx_lic, qr/^score$/);
	my @copy = @list;
	read_table($npi, drop_cols => \@list);
	is_deeply(\@list, \@copy, 'the pattern list is not changed');
	'abc' =~ /(b)/;
	read_table($npi, drop_cols => $rx_lic);
	is($1, 'b', "the caller's \$1 survives the read");
}

#--------
# leaks
#--------
# Every qr// is compiled out here, not inside a block: perl 5.10.0's pp_qr()
# leaks an SV each time a qr// is evaluated, which Test::LeakTrace would report
# against the no_leaks_ok line.
my $rx_none  = qr/^no such column$/;
my $rx_all   = qr/./;
my $rx_ab    = qr/^[ab]$/;
my $rx_score = qr/^score$/;
my @rx_list  = ($rx_lic, $rx_score);
my $cls_ok   = { NPI => 'integer', 'Provider License Number_1' => 'numeric' };
my $cls_bad  = { score => 'integer' };
my $flt_excl = { 'Provider License Number_1' => sub { defined $_ } };
my $flt_row  = sub { $_[0][3] ne 'IL' };
my $ragged   = spew('csv', "id,a,b,c\n1,2,3,4\n5,6\n");
my $xlsx     = File::Spec->catfile($dir, 'book.xlsx');
my @name_list = ('Provider License Number_1', $rx_score, 'Entity Type Code');
my $bad_arg   = { a => 1 };
my $quiet     = sub { };	# made out here: a closure made inside the block is an SV it would count
unless ($INC{'Devel/Cover.pm'}) {
	for my $otype (qw(aoa aoh hoa hoh)) {
		no_leaks_ok {
			eval { read_table($npi, output_type => $otype, drop_cols => $rx_lic) }
		} "read_table(drop_cols): no memory leaks, $otype";
		no_leaks_ok {
			eval { read_table($npi, output_type => $otype, drop_cols => \@rx_list, colClasses => $cls_ok) }
		} "read_table(drop_cols, colClasses): no memory leaks, $otype";
		no_leaks_ok {
			eval { read_table($npi, output_type => $otype, drop_cols => $rx_lic, filter => $flt_excl) }
		} "read_table(drop_cols, filter on an excluded column): no memory leaks, $otype";
		no_leaks_ok {
			eval { read_table($npi, output_type => $otype, drop_cols => $rx_lic, filter => $flt_row) }
		} "read_table(drop_cols, whole-row filter): no memory leaks, $otype";
		no_leaks_ok {
			eval { read_table($npi, output_type => $otype, drop_cols => $rx_lic, colClasses => $cls_bad) }
		} "read_table(drop_cols) croaking on colClasses: no memory leaks, $otype";
		no_leaks_ok {
			eval { read_table($npi, output_type => $otype, drop_cols => $rx_lic, colClasses => $cls_bad,
				filter => $flt_excl) }
		} "read_table(drop_cols, filter) croaking on colClasses: no memory leaks, $otype";
		no_leaks_ok {
			eval { read_table($ragged, output_type => $otype, drop_cols => $rx_ab) }
		} "read_table(drop_cols) croaking on a ragged row: no memory leaks, $otype";
		no_leaks_ok {
			eval { read_table($npi, output_type => $otype, drop_cols => $rx_all) }
		} "read_table(drop_cols) with every column excluded: no memory leaks, $otype";
		no_leaks_ok {
			eval { read_table($npi, output_type => $otype, drop_cols => $rx_none) }
		} "read_table(drop_cols) matching nothing: no memory leaks, $otype";
		# the exchange for an empty pattern compiles nothing: see
		# _rx_for_match() in lib/Stats/LikeR.pm
		no_leaks_ok {
			eval { read_table($npi, output_type => $otype, drop_cols => $rx_empty) }
		} "read_table(drop_cols) with an empty pattern: no memory leaks, $otype";
		no_leaks_ok {
			eval { read_table($npi, output_type => $otype, drop_cols => 'score') }
		} "read_table(drop_cols) by one name: no memory leaks, $otype";
		no_leaks_ok {
			eval { read_table($npi, output_type => $otype, drop_cols => \@name_list) }
		} "read_table(drop_cols) by names and a pattern: no memory leaks, $otype";
		no_leaks_ok {
			eval { read_table($npi, output_type => $otype, drop_cols => \@name_list, _closure => 1) }
		} "read_table(drop_cols) by names, by the closure: no memory leaks, $otype";
		no_leaks_ok {
			eval { read_table($npi, output_type => $otype, drop_cols => $rx_lic, _closure => 1) }
		} "read_table(drop_cols) by the closure: no memory leaks, $otype";
		no_leaks_ok {
			eval { read_table($xlsx, output_type => $otype, drop_cols => $rx_lic) }
		} "read_table(drop_cols) on an .xlsx: no memory leaks, $otype";
	}
	no_leaks_ok {
		eval { read_table($npi, drop_cols => $bad_arg) }
	} 'read_table(drop_cols) refusing its argument: no memory leaks';
	no_leaks_ok {
		local $SIG{__WARN__} = $quiet;
		eval { read_table($npi, drop_cols => 'no such column') }
	} 'read_table(drop_cols) warning of an absent name: no memory leaks';
	no_leaks_ok {
		eval { read_table($npi, output_type => 'hoh', drop_cols => $rx_none, row_names => 'NPI') };
		eval { read_table($npi, output_type => 'hoh', drop_cols => $rx_score, row_names => 'score') };
	} 'read_table(drop_cols) and row_names: no memory leaks';
}

done_testing();
