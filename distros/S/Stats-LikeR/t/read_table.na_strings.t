#!/usr/bin/env perl
# read_table's na_strings / na_values / undef_val option: field texts that mean
# "missing". One option under three names -- R's, pandas', and write_table's.
#
# Provenance of every expected value below.
#
# R (development tree at /home/con/Scripts/r-source, VERSION "4.7.0 Under
# development (unstable)"):
#
#   tests/reg-tests-1a.R:1911-1918  read.table(tmp, na.strings="foo") on a
#                                   two-row file whose second column is
#                                   "foo" then "NA" -- upstream comment
#                                   "related example" (to the type.convert
#                                   case above it), asserting
#                                   is.na(z$V2) == c(TRUE, FALSE) and
#                                   levels(z$V2) == "NA".
#   tests/reg-tests-1a.R:2899-2901  type.convert(c("abc","-"), as.is=TRUE,
#                                   na.strings="-"), upstream "type.convert
#                                   quirk (PR#6781)": res1[2] is NA and the
#                                   mode stays character.
#   src/library/utils/man/read.table.Rd:124-129  the na.strings entry: "a
#                                   character vector of strings which are to
#                                   be interpreted as NA values. Blank fields
#                                   are also considered to be missing values
#                                   ... the test happens *after* white space
#                                   is stripped from the input (if enabled)".
#
# pandas 2.2.3
# (/home/con/.pyenv/versions/3.14.2/lib/python3.14/site-packages/pandas),
# tests/io/parser/test_na_values.py:
#
#   test_string_nas:28              empty fields are missing
#   test_detect_string_na:46        "NA", "NaN", "nan" are missing
#   test_non_string_na_values:90    upstream "see gh-3611": na_values
#                                   ["-999.0", "-999"] against both "-999"
#                                   and "-999.000"
#   test_default_na_values:114      the 19-token STR_NA_VALUES default set
#   test_custom_na_values:163       na_values as a scalar and as a one-element
#                                   list must agree
#   test_na_trailing_columns:461    a row short of the header
#   test_na_values_scalar:495       upstream "see gh-12224": a *numeric*
#                                   na_values scalar
#   test_na_values_dict_aliasing:517 the caller's na_values structure is not
#                                   mutated
#
# The R cases were re-run against the installed R -- /usr/bin/Rscript, "R
# version 4.6.1 (2026-06-24)", one minor release behind the source tree above --
# and the pandas cases against the pandas above, while writing this file. The
# expected values here are the frozen results, and the tests never invoke
# either one.
#
# Three divergences from pandas are asserted deliberately, each because
# Stats::LikeR follows R instead. See the DIVERGENCE blocks below.

require 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::Exception;
use File::Temp 'tempfile';
use File::Spec;
use Stats::LikeR;

# write_table announces every write on file descriptor 1 directly, which the
# documentation notes a `local *STDOUT` cannot intercept, so redirect the
# descriptor itself to keep the TAP stream clean.
sub quiet_write {
	open my $saved, '>&', \*STDOUT or die "dup STDOUT: $!";
	open STDOUT, '>', File::Spec->devnull or die "open devnull: $!";
	write_table(@_);
	open STDOUT, '>&', $saved or die "restore STDOUT: $!";
	close $saved;
	return;
}

sub tmpfile {
	my ($content, $suffix) = @_;
	my ($fh, $name) = tempfile( SUFFIX => ($suffix || '.csv'), UNLINK => 1 );
	binmode $fh;
	print $fh $content;
	close $fh;
	return $name;
}

# The default is unchanged: with no na_strings, a literal "NA" is real data.
#
# This is what t/read_table.t already pins ("a literal 'NA' is preserved
# verbatim"), restated here so that turning the default on later cannot pass
# this file silently. R's read.table defaults to na.strings = "NA" and pandas
# recognises a 19-token set by default; Stats::LikeR recognises none, so the
# option is opt-in.
{
	my $f = tmpfile("a,b\nNA,1\n2,NaN\n");
	my $rows = read_table($f);
	is( $rows->[0]{a}, 'NA',  'no na_strings: a literal "NA" stays a string' );
	is( $rows->[1]{b}, 'NaN', 'no na_strings: a literal "NaN" stays a string' );
}

# R reg-tests-1a.R:1911-1918 -- na.strings="foo".
#
# The file is "1 foo" / "2 NA" and na.strings is "foo", so column 2 is missing
# in row 1 and the *string* "NA" in row 2. It pins both halves at once: the
# listed token maps, and an unlisted "NA" does not.
{
	my $f = tmpfile("V1 V2\n1 foo\n2 NA\n", '.txt');
	for my $opt ('na_strings', 'na_values', 'undef_val') {
		my $rows = read_table($f, sep => ' ', $opt => 'foo');
		ok( !defined $rows->[0]{V2}, "$opt => 'foo' makes \"foo\" missing" );
		is( $rows->[1]{V2}, 'NA',
			"$opt => 'foo' leaves an unlisted \"NA\" alone (R levels(V2) == \"NA\")" );
	}
}

# R reg-tests-1a.R:2899-2901 (PR#6781) -- na.strings="-" over c("abc","-").
{
	my $f = tmpfile("x\nabc\n-\n");
	my $rows = read_table($f, 'na_strings' => '-');
	is( $rows->[0]{x}, 'abc', 'PR#6781: "abc" is untouched' );
	ok( !defined $rows->[1]{x}, 'PR#6781: "-" is missing under na_strings => "-"' );
}

# pandas test_detect_string_na:46 -- "NA", "NaN" and "nan" all missing.
# pandas gets these from its default set; here they are named explicitly.
{
	my $f = tmpfile("A,B\nfoo,bar\nNA,baz\nNaN,nan\n");
	my $rows = read_table($f, na_values => [ 'NA', 'NaN', 'nan' ]);
	is( $rows->[0]{A}, 'foo', 'test_detect_string_na: row 0 A' );
	is( $rows->[0]{B}, 'bar', 'test_detect_string_na: row 0 B' );
	ok( !defined $rows->[1]{A}, 'test_detect_string_na: "NA" is missing' );
	is( $rows->[1]{B}, 'baz',   'test_detect_string_na: row 1 B' );
	ok( !defined $rows->[2]{A}, 'test_detect_string_na: "NaN" is missing' );
	ok( !defined $rows->[2]{B}, 'test_detect_string_na: "nan" is missing' );
}

# pandas test_string_nas:28 -- an empty field is missing with or without the
# option, since read_table has always mapped '' to undef.
{
	my $data = "A,B,C\na,b,c\nd,,f\n,g,h\n";
	for my $args ( [], [ 'na_strings' => 'NA' ] ) {
		my $label = @$args ? 'with na_strings' : 'without na_strings';
		my $rows  = read_table( tmpfile($data), @$args );
		ok( !defined $rows->[1]{B}, "test_string_nas: empty middle field is missing, $label" );
		ok( !defined $rows->[2]{A}, "test_string_nas: empty leading field is missing, $label" );
		is( $rows->[1]{A}, 'd', "test_string_nas: neighbours intact, $label" );
	}
}

# pandas test_custom_na_values:163 -- a scalar and a one-element list agree.
#
# DIVERGENCE (pandas): pandas *adds* na_values to its default set, so its
# expected frame also has "1.#IND" and "NaN" missing here. R replaces the set
# outright, and so does this module: only "baz" is missing below. Verified
# against pandas 2.2.3, which reports rows
# [[F,T,F],[T,F,T],[F,F,T]] as missing for the same file.
{
	my $data = "A,B,C\n1,NA,3\n-1.#IND,5,baz\n7,8,NaN\n";
	for my $na ( 'baz', ['baz'] ) {
		my $label = ref $na ? 'arrayref' : 'scalar';
		my $rows  = read_table( tmpfile($data), 'na_strings' => $na );
		ok( !defined $rows->[1]{C}, "test_custom_na_values: \"baz\" is missing ($label)" );
		is( $rows->[0]{B}, 'NA',
			"test_custom_na_values: unlisted \"NA\" survives ($label) -- R semantics, not pandas'" );
		is( $rows->[1]{A}, '-1.#IND',
			"test_custom_na_values: unlisted \"-1.#IND\" survives ($label)" );
		is( $rows->[2]{C}, 'NaN',
			"test_custom_na_values: unlisted \"NaN\" survives ($label)" );
	}
}

# pandas test_non_string_na_values:90 (gh-3611) -- na_values ["-999.0","-999"].
#
# DIVERGENCE (pandas): pandas numifies both the token and the field, so
# "-999.000" matches "-999.0" and its expected frame has it missing. R compares
# the text, so "-999.000" is not missing -- confirmed by running
# read.csv(f, na.strings=c("-999.0","-999")) on this exact file, which reports
# is.na only for the "-999" cell. This module matches R.
{
	my $f = tmpfile("A,B\n-999,1.200\n2,-999.000\n3,4.500\n");
	my $rows = read_table($f, 'na_strings' => [ '-999.0', '-999' ]);
	ok( !defined $rows->[0]{A}, 'gh-3611: the exact text "-999" is missing' );
	is( $rows->[1]{B}, '-999.000',
		'gh-3611: "-999.000" is NOT missing -- exact text match, as in R' );
	is( $rows->[0]{B}, '1.200', 'gh-3611: "1.200" is untouched' );
	is( $rows->[2]{B}, '4.500', 'gh-3611: "4.500" is untouched' );
}

# pandas test_default_na_values:114 -- the whole STR_NA_VALUES set works when
# passed explicitly. The list is pandas 2.2.3's, read out of
# pandas._libs.parsers.STR_NA_VALUES and sorted; '' is dropped because an
# empty field is already missing and listing it would prove nothing.
{
	my @pandas_default = (
		'#N/A', '#N/A N/A', '#NA', '-1.#IND', '-1.#QNAN', '-NaN', '-nan',
		'1.#IND', '1.#QNAN', '<NA>', 'N/A', 'NA', 'NULL', 'NaN', 'None',
		'n/a', 'nan', 'null',
	);
	my $f = tmpfile( "tok\n" . join('', map { "$_\n" } @pandas_default) );
	my $rows = read_table($f, na_values => \@pandas_default);
	is( scalar @$rows, scalar @pandas_default, 'test_default_na_values: every row read' );
	my @survived = grep { defined $rows->[$_]{tok} } 0 .. $#$rows;
	is_deeply( \@survived, [],
		'test_default_na_values: all 18 non-empty pandas default tokens map to undef' );
}

# pandas test_na_values_scalar:495 (gh-12224) -- a numeric na_values scalar.
# Perl has no int/str distinction to trip over here, but the case still pins
# that a bare number is accepted and compared as its text.
{
	my $f = tmpfile("a,b\n1,2\n2,1\n");
	my $rows = read_table($f, 'na_strings' => 1);
	ok( !defined $rows->[0]{a}, 'gh-12224: numeric na_strings => 1 matches "1" in column a' );
	is( $rows->[0]{b}, '2',    'gh-12224: "2" is untouched' );
	is( $rows->[1]{a}, '2',    'gh-12224: "2" is untouched in column a' );
	ok( !defined $rows->[1]{b}, 'gh-12224: and "1" in column b' );
}

# pandas test_na_values_dict_aliasing:517 -- the caller's structure survives.
{
	my @na   = ( 'NA', 'missing' );
	my @copy = @na;
	my $f = tmpfile("a,b\nNA,1\nmissing,2\n");
	read_table($f, na_values => \@na);
	is_deeply( \@na, \@copy,
		'test_na_values_dict_aliasing: the caller\'s arrayref is not modified' );
}

# pandas test_na_trailing_columns:461.
#
# DIVERGENCE (pandas): pandas pads a short row with NaN. read_table has always
# refused a ragged file with an alignment error naming the row, and that is not
# changed by na_strings; the test is here so the divergence is deliberate
# rather than discovered.
{
	my $f = tmpfile("Date,Currency,Symbol,Type,Units,UnitPrice,Cost,Tax\n"
	              . "2012-03-14,USD,AAPL,BUY,1000\n");
	throws_ok { read_table($f, 'na_strings' => 'NA') }
		qr/Alignment error on .* data row 1 \(5 fields vs 8 headers\)/,
		'test_na_trailing_columns: a short row is still an alignment error, not NA padding';
}

# The bug this option exists for: write_table's own output could not be read
# back. write_table renders undef with 'undef_val' (documented as "does not
# round-trip back to undef"), and na_strings is the inverse it lacked.
#
# 'undef_val' is accepted here as a third name for the same option precisely so
# that the round trip can be written with one spelling on both halves, which is
# what the third pass below does.
{
	my ($fh, $file) = tempfile( SUFFIX => '.csv', UNLINK => 1 );
	close $fh;
	my $rows = [ { id => 1, v => 10 }, { id => 2, v => undef } ];
	quiet_write($rows, $file, 'row_names' => 0, 'undef_val' => 'NA');

	my $naive = read_table($file);
	is( $naive->[1]{v}, 'NA',
		'round trip: without na_strings, undef_val comes back as the string' );

	for my $opt ('na_strings', 'na_values', 'undef_val') {
		my $back = read_table($file, $opt => 'NA');
		is( $back->[0]{v}, '10', "round trip ($opt): a real value is unchanged" );
		ok( !defined $back->[1]{v},
			"round trip ($opt): undef_val => \"NA\" reads back as undef" );
	}
}

# The numeric consequence, which is why the round trip mattered.
#
# Through 0.311 an unmapped "NA" numified to 0 and silently dragged the mean
# down -- this block asserted mean() == 3 rather than 3.75, with `no warnings
# 'numeric'` around it because the warning was the only signal there was.
# Since 0.312 mean() refuses a value that is not a number instead, so the
# signal is the exception, and it does not depend on the caller's warning
# settings reaching an XSUB (they never did).
#
# Every value and the mean are exactly representable in binary (8, 4, 2, 1 and
# 15/4 = 3.75), so this compares exactly on a double, long-double or __float128
# perl -- no tolerance is needed or wanted here.
{
	my $f = tmpfile("v\n8\n4\n2\n1\nNA\n");

	my $unmapped = read_table($f, 'output_type' => 'hoa');
	my $err = do { local $@; eval { mean( $unmapped->{v} ) }; $@ };
	like( $err, qr/^mean: non-numeric value at array ref index 4/,
		'an unmapped literal "NA" makes mean() croak, naming the cell' );

	my $mapped = read_table($f, 'na_strings' => 'NA', 'output_type' => 'hoa');
	my @defined = grep { defined } @{ $mapped->{v} };
	is( scalar @defined, 4, 'na_strings leaves 4 defined values of 5' );
	is( mean(\@defined), 3.75, 'and their mean is 3.75, as R and pandas give' );
}

# Every output_type sees the mapping.
{
	my $data = "id,v\nr1,NA\nr2,7\n";
	my $aoh = read_table( tmpfile($data), 'output_type' => 'aoh', 'na_strings' => 'NA' );
	ok( !defined $aoh->[0]{v}, 'aoh: mapped' );
	is( $aoh->[1]{v}, '7',     'aoh: untouched neighbour' );

	my $hoa = read_table( tmpfile($data), 'output_type' => 'hoa', 'na_strings' => 'NA' );
	ok( !defined $hoa->{v}[0], 'hoa: mapped' );
	is( $hoa->{v}[1], '7',     'hoa: untouched neighbour' );
	is( scalar @{ $hoa->{v} }, 2, 'hoa: the column keeps its length' );

	my $hoh = read_table( tmpfile($data), 'output_type' => 'hoh', 'na_strings' => 'NA' );
	ok( !defined $hoh->{r1}{v}, 'hoh: mapped' );
	is( $hoh->{r2}{v}, '7',     'hoh: untouched neighbour' );
}

# A mapped row-name column is a missing row name, and dies as one.
{
	my $f = tmpfile("id,v\nNA,1\nr2,2\n");
	throws_ok { read_table($f, 'output_type' => 'hoh', 'na_strings' => 'NA') }
		qr/read_table: undefined row name \(column 'id'\)/,
		'a row name mapped to undef is refused, like an empty one';
}

# The header is never mapped: a column may legitimately be called "NA".
{
	my $f = tmpfile("a,NA\n1,NA\n");
	my $rows = read_table($f, 'na_strings' => 'NA');
	ok( exists $rows->[0]{'NA'}, 'a column literally named "NA" keeps its name' );
	ok( !defined $rows->[0]{'NA'}, 'while its cell is mapped' );
}

# A filter runs after the mapping, so it sees undef rather than the token.
{
	my $f = tmpfile("a,b\nNA,1\n5,2\n");
	my @seen;
	my $rows = read_table($f, 'na_strings' => 'NA',
		filter => { a => sub { push @seen, defined $_ ? $_ : '(undef)'; 1 } });
	is_deeply( \@seen, [ '(undef)', '5' ],
		'a filter sees the mapped undef, not the "NA" text' );
	is( scalar @$rows, 2, 'and nothing was dropped' );

	# Filtering *out* the missing rows is then a defined() test.
	my $kept = read_table($f, 'na_strings' => 'NA',
		filter => { a => sub { defined $_ } });
	is( scalar @$kept, 1, 'filter => { a => sub { defined $_ } } drops the missing row' );
	is( $kept->[0]{a}, '5', 'and keeps the other' );
}

# It composes with the other parsing options: a tab file, and a commented-out
# header (t/read_table.comments.t covers that recovery on its own).
{
	my $f = tmpfile("a\tb\n1\t-\n", '.tsv');
	my $rows = read_table($f, 'na_strings' => '-');
	ok( !defined $rows->[0]{b}, 'na_strings works with a .tsv default separator' );

	my $c = tmpfile("# a,b\n1,-\n");
	my $crows = read_table($c, 'na_strings' => '-');
	ok( !defined $crows->[0]{b}, 'na_strings works under a commented-out header' );
	is( $crows->[0]{a}, '1', 'and the recovered header still names the columns' );
}

# Turning it off, both ways.
{
	my $data = "a\nNA\n";
	for my $off ( [ 'na_strings' => undef ], [ 'na_strings' => [] ],
	              [ na_values   => undef ], [ na_values   => [] ],
	              [ 'undef_val' => undef ], [ 'undef_val' => [] ] ) {
		my $label = "$off->[0] => " . ( defined $off->[1] ? '[]' : 'undef' );
		my $rows  = read_table( tmpfile($data), @$off );
		is( $rows->[0]{a}, 'NA', "$label leaves the default behaviour alone" );
	}
}

# Argument validation.
{
	my $f = tmpfile("a\n1\n");

	# Any two of the three spellings together are refused, as sep and delim
	# are, and the message names them in a fixed order whichever way round
	# they were passed.
	my @pairs = (
		[ 'na_strings' => 'NA', 'na_values'  => 'NA' ],
		[ 'na_values'  => 'NA', 'na_strings' => 'NA' ],
		[ 'na_strings' => 'NA', 'undef_val'  => 'NA' ],
		[ 'undef_val'  => 'NA', 'na_strings' => 'NA' ],
		[ 'na_values'  => 'NA', 'undef_val'  => 'NA' ],
		[ 'undef_val'  => 'NA', 'na_values'  => 'NA' ],
	);
	for my $pair (@pairs) {
		my ($a, $b) = ( $pair->[0], $pair->[2] );
		throws_ok { read_table($f, @$pair) }
			qr/^read_table: pass only one of 'na_strings', 'na_values' or 'undef_val'; got '[^']+', '[^']+'$/m,
			"$a and $b together are refused";
	}

	throws_ok { read_table($f, 'na_strings' => 'NA', na_values => 'NA', 'undef_val' => 'NA') }
		qr/^read_table: pass only one of 'na_strings', 'na_values' or 'undef_val'; got 'na_strings', 'na_values', 'undef_val'$/m,
		'all three together are refused, and the message lists them in a fixed order';

	throws_ok { read_table($f, 'na_strings' => {}) }
		qr/^read_table: 'na_strings' must be a string or an ARRAY reference, not a HASH reference$/m,
		'a hashref is refused (pandas takes a dict here; this module does not)';

	throws_ok { read_table($f, na_values => sub { 1 }) }
		qr/^read_table: 'na_strings' must be a string or an ARRAY reference, not a CODE reference$/m,
		'a coderef is refused, and reports under the canonical option name';

	throws_ok { read_table($f, 'undef_val' => \'NA') }
		qr/^read_table: 'na_strings' must be a string or an ARRAY reference, not a SCALAR reference$/m,
		'undef_val is validated the same way, and also reports as na_strings';

	throws_ok { read_table($f, 'na_strings' => [ 'NA', undef ]) }
		qr/^read_table: 'na_strings' may not contain an undefined value$/m,
		'an undef inside the list is refused rather than silently matching nothing';

	throws_ok { read_table($f, 'na_string' => 'NA') }
		qr/aren't defined for read_table/,
		'a misspelled option is still refused by the allowed-args check';
}

# Duplicates in the list, and a token that is itself the empty string, are
# both harmless -- the empty field rule already covers ''.
{
	my $f = tmpfile("a,b\nNA,\n");
	my $rows = read_table($f, 'na_strings' => [ 'NA', 'NA', '' ]);
	ok( !defined $rows->[0]{a}, 'a duplicated token is harmless' );
	ok( !defined $rows->[0]{b}, "and '' in the list agrees with the empty-field rule" );
}

# read.table.Rd:124-129 notes that R strips white space *before* comparing.
# read_table does not strip, so " NA" is not "NA" -- list both if a file has
# both. Asserted so the choice is on the record.
{
	my $f = tmpfile("a,b\n NA,NA \n");
	my $rows = read_table($f, 'na_strings' => 'NA');
	is( $rows->[0]{a}, ' NA', 'no leading whitespace is stripped before matching' );
	is( $rows->[0]{b}, 'NA ', 'nor trailing' );

	my $both = read_table( tmpfile("a,b\n NA,NA \n"),
		'na_strings' => [ 'NA', ' NA', 'NA ' ] );
	ok( !defined $both->[0]{a}, 'listing the padded form maps it (a)' );
	ok( !defined $both->[0]{b}, 'listing the padded form maps it (b)' );
}

# The .xlsx path shares read_table's callback, so it maps too. write_table's
# xlsx writer supplies the file, which keeps this free of a binary fixture.
{
	my ($fh, $file) = tempfile( SUFFIX => '.xlsx', UNLINK => 1 );
	close $fh;
	quiet_write( [ { id => 1, v => 10 }, { id => 2, v => undef } ],
		$file, 'row_names' => 0, 'undef_val' => 'NA' );
	my $back = read_table($file, na_values => 'NA');
	is( $back->[0]{v}, '10', 'xlsx: a real value is unchanged' );
	ok( !defined $back->[1]{v}, 'xlsx: a shared-string "NA" maps to undef' );
}

done_testing();
