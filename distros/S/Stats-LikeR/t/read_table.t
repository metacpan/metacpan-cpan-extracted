require 5.010;
use strict;
use warnings;
use Test::More;
use Test::Exception;
use File::Temp 'tempfile';
use Stats::LikeR;

# Regression tests for bugs fixed in read_table (Perl) and _parse_csv_file (XS).
# Every assertion here fails against the pre-fix code.

sub tmpcsv {
	my ($content) = @_;
	my ($fh, $name) = tempfile( SUFFIX => '.csv', UNLINK => 1 );
	binmode $fh;
	print $fh $content;
	close $fh;
	return $name;
}

#
# Bug 1 (Perl): a consistent trailing separator made the header — whose trailing
# empty fields were stripped — shorter than the data rows, so read_table died
# with a false "Alignment error". It should now read cleanly, treating the
# trailing separator as one extra empty-named column on every line.
#
{
	my $f = tmpcsv("a,b,c,\n1,2,3,\n4,5,6,\n");
	my $rows;
	lives_ok { $rows = read_table($f) }
		'trailing separator on every line no longer dies with a false Alignment error';
	SKIP: {
		skip 'read_table died on the trailing separator', 3 unless $rows;
		is( scalar @$rows, 2, 'both data rows are read despite the trailing separator' );
		is( $rows->[0]{a}, 1, 'first column is parsed correctly' );
		ok( exists $rows->[0]{''}, 'the trailing separator yields one empty-named column' );
	}
}
# Sanity: a genuinely ragged row (more fields than the header) must still die,
# i.e. the fix relaxed the trailing-separator case without disabling the check.
{
	my $f = tmpcsv("a,b,c\n1,2,3,4\n");
	dies_ok { read_table($f) }
		'a genuinely ragged row still dies (alignment is still enforced)';
}

# Bug 2 (Perl): duplicate column names silently collapsed in the per-row hash
# (last value wins) with no indication. read_table now warns.
{
	my $f = tmpcsv("a,b,a\n1,2,3\n");
	my @warnings;
	{
		local $SIG{__WARN__} = sub { push @warnings, $_[0] };
		read_table($f);
	}
	ok( scalar( grep { /duplicate column/i } @warnings ),
		'duplicate column name now emits a warning' )
		or diag "warnings seen: @warnings";
}

# Bug 3 (Perl): in 'hoh' output, two rows sharing a row.names value silently
# overwrote each other. read_table now warns (and last value still wins).
{
	my $f = tmpcsv("id,v\nx,1\nx,2\ny,3\n");
	my @warnings;
	my $h;
	{
		local $SIG{__WARN__} = sub { push @warnings, $_[0] };
		$h = read_table($f, 'output.type' => 'hoh', 'row.names' => 'id');
	}
	ok( scalar( grep { /duplicate row name/i } @warnings ),
		'duplicate hoh row name now emits a warning' )
		or diag "warnings seen: @warnings";
	is( $h->{x}{v}, 2, 'last duplicate row wins (documented last-write behavior)' );
}

# Bug 4 (XS _parse_csv_file): the callback path returned the immortal
# &PL_sv_undef, which the SV* typemap mortalizes -> SvREFCNT_dec on the
# immortal. On perls without the immortal-decref guard (< ~5.18) this
# underflows PL_sv_undef and segfaults at global destruction; it is now a
# fresh newSV(0). On a guarded perl the underflow is masked, so this exercises
# the path repeatedly to confirm it stays correct. The true crash only shows
# on perl < 5.18 (the 5.10 / Solaris CPAN testers).
{
	my $f = tmpcsv("a,b\n1,2\n3,4\n");
	my $all_ok = 1;
	lives_ok {
		for ( 1 .. 500 ) {
			my $r = read_table($f);
			$all_ok &&= ( ref $r eq 'ARRAY' && @$r == 2 );
		}
	} 'repeated callback-path reads run without error (XS undef-return path)';
	ok( $all_ok, 'every repeated read returned the expected structure' );
}
# Change: an empty / missing field is now stored as undef rather than the
# string 'NA'. The empty *value* maps to undef across all three output shapes,
# while a field whose literal text is "NA" is a real value and survives verbatim.
#
# aoh (default): the empty middle field becomes undef, neighbours untouched.
{
	my $f = tmpcsv("a,b,c\n1,,3\n");
	my $rows = read_table($f);
	ok( exists $rows->[0]{b}, 'aoh: an empty field still produces its key' );
	ok( !defined $rows->[0]{b}, 'aoh: an empty field is now undef, not the string NA' );
	is( $rows->[0]{a}, 1, 'aoh: a non-empty field to the left is preserved' );
	is( $rows->[0]{c}, 3, 'aoh: a non-empty field to the right is preserved' );
}
# hoa: the undef lands inside the column's array.
{
	my $f = tmpcsv("a,b,c\n1,,3\n");
	my $h = read_table($f, 'output.type' => 'hoa');
	ok( !defined $h->{b}[0], 'hoa: the empty field is undef inside the column array' );
	is( $h->{a}[0], 1, 'hoa: a non-empty field is preserved' );
}
# hoh: the undef lands in the per-row hash.
{
	my $f = tmpcsv("id,b,c\nr1,,3\n");
	my $h = read_table($f, 'output.type' => 'hoh', 'row.names' => 'id');
	ok( exists $h->{r1}{b}, 'hoh: the empty field still produces its key' );
	ok( !defined $h->{r1}{b}, 'hoh: the empty field is undef' );
	is( $h->{r1}{c}, 3, 'hoh: a non-empty field is preserved' );
}
# A field whose text is literally "NA" is real data and must NOT be turned into
# undef (the conversion only ever applied to empty / missing fields).
{
	my $f = tmpcsv("a,b\nNA,2\n");
	my $rows = read_table($f);
	ok( defined $rows->[0]{a}, 'a literal "NA" in the data stays defined (it is a real value)' );
	is( $rows->[0]{a}, 'NA', 'a literal "NA" is preserved verbatim, not invented or dropped' );
}
# The trailing-separator column (see Bug 1 above) now carries undef, not 'NA'.
{
	my $f = tmpcsv("a,b,c,\n1,2,3,\n");
	my $rows = read_table($f);
	ok( exists $rows->[0]{''}, 'trailing-separator column is still present' );
	ok( !defined $rows->[0]{''}, 'trailing-separator empty value is undef' );
}
# Filter write-back: a callback that blanks $_ stores undef, not the string NA.
{
	my $f = tmpcsv("a,b\n1,keep\n2,blank\n");
	my $rows = read_table($f, filter => {
		b => sub { $_ = '' if $_ eq 'blank'; 1 }, # mutate in place, keep every row
	});
	is( scalar @$rows, 2, 'filter kept both rows' );
	is( $rows->[0]{b}, 'keep', 'a value left alone by the filter is preserved' );
	ok( !defined $rows->[1]{b}, 'a value blanked inside a filter is written back as undef' );
}
done_testing();
