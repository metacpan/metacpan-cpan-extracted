#!/usr/bin/env perl
# filter() with a compiled predicate over two columns, where a tied cell read by
# the first leaf clears the row (AoH, HoH) or the column (HoA) that the second
# leaf's cell lives in.  Found by the 2026-11-03 audit: flt_row_hv() and
# flt_row_hoa() filled pg->cells[] with borrowed pointers for every column
# before evaluation began, so the second leaf read a freed scalar.  Perl frees
# an SV into its own arena, which valgrind cannot see, so the freed read is
# silent there (valgrind was clean on the unfixed code too) and the unfixed
# build usually returned an answer by luck; what the cases pin is the defined
# behavior now: when any cell of a row is magical, all of the row's cells are
# held for the evaluation, so the row is judged on the values it had when
# its test began, even if a FETCH removes them.
#
# The cases are this module's own: R and SciPy have no tied cells.  The answer
# asserted is what a perl closure gives for the same frame.

require 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Stats::LikeR qw(filter col);

# A tied scalar whose first FETCH runs $code; every FETCH returns $value.
{
	package OnceThen;
	sub TIESCALAR { my ($class, $value, $code) = @_; return bless { v => $value, code => $code }, $class }
	sub FETCH {
		my $self = shift;
		if (my $code = delete $self->{code}) { $code->() }
		return $self->{v};
	}
	sub STORE { $_[0]{v} = $_[1] }
}

my $pred = (col('a') > 0) & (col('b') > 0);	# two leaves, two columns

# AoH: the first cell's FETCH empties the row hash holding the second cell.
{
	my $row = { b => 5 };
	tie $row->{a}, 'OnceThen', 1, sub { %$row = () };
	my $out = filter([ $row, { a => 1, b => 2 } ], $pred);
	ok(ref $out eq 'ARRAY', 'AoH: filter() survives a FETCH that clears the row');
	is(scalar @$out, 2, 'AoH: the row is judged on the cells it held (a = 1, b = 5), and the other row is kept');
}

# HoH: the same through a hash of rows.
{
	my $row = { b => 5 };
	tie $row->{a}, 'OnceThen', 1, sub { %$row = () };
	my $out = filter({ r1 => $row, r2 => { a => 1, b => 2 } }, $pred);
	ok(ref $out eq 'HASH', 'HoH: filter() survives a FETCH that clears the row');
}

# HoA: the first column's FETCH replaces the second column's array.
{
	my $bcol = [ 5, 6 ];
	my %d = (b => $bcol);
	my @a = (0, 1);
	tie $a[0], 'OnceThen', 1, sub { @$bcol = () };
	$d{a} = \@a;
	my $out = filter(\%d, $pred);
	ok(ref $out eq 'HASH', 'HoA: filter() survives a FETCH that empties the other column');
}

done_testing();
