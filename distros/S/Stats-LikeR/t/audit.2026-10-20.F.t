#!/usr/bin/env perl
# Regressions for the data-helper bugs the 2026-10-20 audit found in 0.33:
# csort(), aoh2hoa(), group_by() and mode(). The rest of that list has its
# tests beside the function's others: write_table's multi-byte separator in
# t/write_table.quoting.t, csort's out-of-range AoA index in t/csort.AoA.t,
# read_table's CR file with a quoted LF in t/read_table.cr_eol.R.pandas.t, and
# the croak leaks of aoh2hoa, hoa2aoh and hoa2hoh in t/croak.leaks.t.
#
# Provenance of the expected orders, R 4.6.1 (2026-06-24):
#
#   x <- c(3, NaN, 1, NA, 2, NaN)
#   order(x)                          3 5 1 2 4 6
#   order(x, decreasing = TRUE)       1 5 3 2 4 6
#   y <- c(-Inf, NaN, Inf, 0)
#   order(y)                          1 4 3 2
#   order(y, decreasing = TRUE)       3 4 1 2
#   split(c(1, 2, 3, 4, 5), c("a", NA, "", "a", NA))
#                                     "" = 3, a = 1 4; the NA rows are dropped
#
# csort has no decreasing switch for a column; a comparator that sorts
# descending ($b <=> $a) is its equivalent, and is held to R's decreasing order.
# Here an undef is R's NA. Everything else is structural: what a tied container
# reads as, and what mode() leaves behind in its caller's array.
require 5.010;
use strict;
use warnings FATAL => 'all';
use B ();
use Tie::Scalar ();
use Test::More;
use Stats::LikeR qw(aoh2hoa csort group_by mode);

my $NAN = 9**9**9 - 9**9**9;
my $INF = 9**9**9;
{
	package TiedArr;	# a tied array whose elements exist only once FETCH runs
	require Tie::Array;
	our @ISA = ('Tie::StdArray');
}
{
	package TiedHash;	# likewise for a hash
	require Tie::Hash;
	our @ISA = ('Tie::StdHash');
}
sub tied_arr { tie my @t, 'TiedArr'; @t = @_; return \@t }
sub tied_hash { tie my %t, 'TiedHash'; %t = @_; return \%t }

# ---- csort: NaN sorts last, with undef, as R's order() puts NaN and NA ----
{
	# order(c(3, NaN, 1, NA, 2, NaN)) = 3 5 1 2 4 6: each row carries its R index
	my @x = (3, 'NaN', 1, undef, 2, $NAN);
	my @aoh = map { { i => $_ + 1, x => $x[$_] } } 0 .. $#x;
	my $order = sub { [ map { $_->{i} } @{ $_[0] } ] };
	is_deeply($order->(csort(\@aoh, 'x')), [3, 5, 1, 2, 4, 6], 'AoH column: as order(x)');
	is_deeply(csort({ i => [1 .. 6], x => \@x }, 'x')->{i}, [3, 5, 1, 2, 4, 6], 'HoA column: as order(x)');
	is_deeply([ map { $_->[0] } @{ csort([ map { [ $_ + 1, $x[$_] ] } 0 .. $#x ], 1) } ],
		[3, 5, 1, 2, 4, 6], 'AoA column: as order(x)');
	my %hoh = map { ("r$_" => $aoh[$_]) } 0 .. $#aoh;
	is_deeply($order->(csort(\%hoh, 'x')), [3, 5, 1, 2, 4, 6], 'HoH column: as order(x)');
	is_deeply($order->(csort(\@aoh, sub { $a->{x} <=> $b->{x} })), [3, 5, 1, 2, 4, 6],
		'comparator ascending: as order(x), and no FATAL uninitialized warning');
	is_deeply($order->(csort(\@aoh, sub { $b->{x} <=> $a->{x} })), [1, 5, 3, 2, 4, 6],
		'comparator descending: as order(x, decreasing = TRUE)');
	# order(c(-Inf, NaN, Inf, 0)) = 1 4 3 2; decreasing 3 4 1 2
	my @y = (-$INF, $NAN, $INF, 0);
	my @aoh_y = map { { i => $_ + 1, y => $y[$_] } } 0 .. $#y;
	is_deeply($order->(csort(\@aoh_y, 'y')), [1, 4, 3, 2], 'infinities sort as numbers, NaN after them');
	is_deeply($order->(csort(\@aoh_y, sub { $b->{y} <=> $a->{y} })), [3, 4, 1, 2],
		'... and descending, NaN still last');
	# a column that is not numeric compares 'NaN' as the string it is
	is_deeply([ map { $_->{s} } @{ csort([ { s => 'b' }, { s => 'NaN' }, { s => 'a' } ], 's') } ],
		['NaN', 'a', 'b'], "in a string column 'NaN' is a string");
}

# ---- csort: tied rows and tied columns are read through FETCH -------------
{
	my $aoa = [ tied_arr(3, 'c'), tied_arr(1, 'a'), tied_arr(2, 'b') ];
	is_deeply([ map { $_->[1] } @{ csort($aoa, 0) } ], [qw(a b c)],
		'AoA of tied rows sorts by its column; it came back unsorted');
	is_deeply(csort($aoa, 0, 'hoa'), { 0 => [1, 2, 3], 1 => [qw(a b c)] }, '... and converts');
	throws_ok_like(sub { csort($aoa, 5) }, qr/column '5' not found/,
		'a tied row is not taken to have a column past its end');
	my $hoa = { x => tied_arr(3, 1, 2), y => [qw(c a b)] };
	is_deeply(csort($hoa, 'x'), { x => [1, 2, 3], y => [qw(a b c)] },
		'HoA with a tied sort column; it came back unsorted');
	my $aoh = [ tied_hash(x => 3), tied_hash(x => 1), tied_hash(x => 2) ];
	is_deeply(csort($aoh, 'x', 'hoa'), { x => [1, 2, 3] }, 'AoH of tied rows (already worked)');
}

# ---- aoh2hoa: tied input ---------------------------------------------------
{
	is_deeply(aoh2hoa(tied_arr({ a => 1 }, { a => 2, b => 3 })), { a => [1, 2], b => [undef, 3] },
		'a tied array of rows; it gave {}');
	is_deeply(aoh2hoa([ tied_hash(a => 5, b => 6), { a => 1 } ]), { a => [5, 1], b => [6, undef] },
		'a tied row; its cells read as undef');
	my %h = (a => 1);
	tie $h{b}, 'Tie::StdScalar', 'TV';
	is_deeply(aoh2hoa([ \%h ]), { a => [1], b => ['TV'] }, 'a tied cell of a plain row');
	is_deeply(aoh2hoa([ { a => 1 }, 'not a row', { a => 3 } ]), { a => [1, undef, 3] },
		'a row that is not a hash still gives undef');
}

# ---- group_by: an undef group drops its row, as split() drops NA ----------
{
	# split(c(1, 2, 3, 4, 5), c("a", NA, "", "a", NA))
	my $want = { '' => [3], a => [1, 4] };
	my @g = ('a', undef, '', 'a', undef);
	my @v = (1 .. 5);
	my @w;
	local $SIG{__WARN__} = sub { push @w, @_ };
	is_deeply(group_by([ map { { g => $g[$_], v => $v[$_] } } 0 .. 4 ], 'v', 'g'), $want,
		'AoH: as split(); it died under FATAL warnings, or pooled undef with ""');
	is_deeply(group_by({ g => \@g, v => \@v }, 'v', 'g'), $want, 'HoA: likewise');
	# a HoH's rows come in hash order, so its groups are compared sorted
	my $hoh = group_by({ map { ("r$_" => { g => $g[$_], v => $v[$_] }) } 0 .. 4 }, 'v', 'g');
	is_deeply({ map { ($_ => [ sort { $a <=> $b } @{ $hoh->{$_} } ]) } keys %$hoh }, $want,
		'HoH: likewise');
	is(scalar(@w), 0, 'no warning at all');
	my @c = ('a', 'b');
	tie $c[1], 'Tie::StdScalar', undef;
	is_deeply(group_by({ g => \@c, v => [1, 2] }, 'v', 'g'), { a => [1] }, 'a tied undef label is dropped too');
}

# ---- mode: a numeric cell is not stringified in place ---------------------
{
	my @a = map { $_ + 0.5 } (1, 2, 2, 3);
	my @i = (7, 7, 8);
	my $before_a = B::class(B::svref_2object(\$a[0]));
	my $before_i = B::class(B::svref_2object(\$i[0]));
	is_deeply([ mode(\@a) ], [2.5], 'mode of NVs');
	is_deeply([ mode(\@i) ], [7], 'mode of IVs');
	is(B::class(B::svref_2object(\$a[0])), $before_a, "an NV cell stays $before_a; it became a PVNV");
	is(B::class(B::svref_2object(\$i[0])), $before_i, "an IV cell stays $before_i; it became a PVIV");
	ok(!(B::svref_2object(\$a[0])->FLAGS & (B::SVf_POK | B::SVp_POK)), 'and has no string form');
	# README: 1, 1.0 and "1" are one value; "1.0" is a string of its own
	is_deeply([ mode(1, 1.0, '1', '1.0', '1.0') ], [1], '1, 1.0 and "1" count together');
	is_deeply([ mode(0, '0', '-0', '-0', '-0') ], ['-0'], '"-0" is a string apart from 0');
	is_deeply([ mode([2.5, '2.5', 1, 1]) ], [2.5, 1], 'a number and its string form count together');
}

sub throws_ok_like {
	my ($code, $re, $name) = @_;
	my $lived = eval { $code->(); 1 };
	ok(!$lived && $@ =~ $re, $name) or diag($lived ? 'lived' : "died: $@");
}

done_testing;
