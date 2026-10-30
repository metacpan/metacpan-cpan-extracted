#!/usr/bin/env perl
# A tied cell whose FETCH changes the frame it is being read from.
#
# oneway_test() and p_adjust() size a buffer in one pass over the frame and
# fill it in a second, and a tied cell's FETCH runs in the second.  Up to 0.341
# the second pass re-read the containers as they then were:
#
# 1. oneway_test(), AoA and hash of groups: a FETCH that grew a later group
#    overran the observation buffer -- "malloc(): unaligned tcache chunk
#    detected" and an abort for the AoA, silent heap corruption that valgrind
#    reported for the hash.  The groups were not held either, so one the FETCH
#    replaced was read after it was freed; formula mode held neither column.
#    Each group is now held and read to the length the first pass measured, so
#    the answer is the one for the frame as it was measured.
#
# 2. p_adjust(), every frame shape: a FETCH that replaced a row with a number
#    had SvRV() taken of the number (a segfault), and one that shrank a row left
#    slots the adjusted values were then written through uninitialised.  The
#    frame, each row and column, and each value are now held, and the second
#    pass checks each row and column again: one replaced, grown or shrunk
#    croaks, and one merely deleted from its container is read as it was.
#
# 3. write_table, cor, cov, cor_test, agg, group_by, filter, merge and ljoin
#    held a borrowed row, column, cell or key across user code; see the
#    comment over that block.
#
# 4. Any XSUB, for the arrays and hashes its arguments refer to.
#
# The cases are this module's own: R and SciPy have no tied cells.

require 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::Exception;
use Test::LeakTrace 'no_leaks_ok';
use Stats::LikeR qw(oneway_test p_adjust write_table cor cov cor_test agg group_by filter merge ljoin);
use File::Temp qw(tempdir);

# A tied scalar whose first FETCH runs $code, and every FETCH returns $value.
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

# oneway_test's statistic and p-value, for comparing two calls
# (the factor's entry is "Group", or in formula mode the factor's own name)
sub ow { my ($r, $f) = @_; return [ map { $r->{$f // 'Group'}{$_} } 'F value', 'Pr(>F)' ] }

# 1. oneway_test
{
	my $want = ow( oneway_test([ [1.5, 2, 3], [1, 2, 4] ]) );
	my $g2 = [1, 2, 4];
	my $g1 = [0, 2, 3];
	tie $g1->[0], 'OnceThen', 1.5, sub { push @$g2, (1) x 200_000 };
	my $got;
	lives_ok { $got = oneway_test([ $g1, $g2 ]) } 'AoA: a FETCH that grows a later group does not overrun';
	is_deeply( ow($got), $want, 'AoA: the groups are read as they were measured' );

	$g2 = [1, 2, 4];
	$g1 = [0, 2, 3];
	tie $g1->[0], 'OnceThen', 1.5, sub { push @$g2, (1) x 200_000 };
	lives_ok { $got = oneway_test({ a => $g1, b => $g2 }) } 'hash of groups: a FETCH that grows a group does not overrun';
	is_deeply( ow($got), $want, 'hash of groups: the groups are read as they were measured' );

	my %h;
	%h = (a => [0, 2, 3], b => [1, 2, 4]);
	my $g1h = $h{a};
	tie $g1h->[0], 'OnceThen', 1.5, sub { delete $h{b}; @{ $h{a} } = () };
	# which cell reads as undef moves with the perl: 1 from 5.18 on, 0 before
	throws_ok { oneway_test({ a => $g1h, b => $h{b} }) } qr/^oneway_test: group 'a', observation [01] is undefined or non-numeric/,
		'hash of groups: a FETCH that empties its own group croaks rather than crash';

	my %df = (y => [0, 2, 3, 1, 2, 4], g => [qw(a a a b b b)]);
	tie $df{y}[0], 'OnceThen', 1.5, sub { $df{y} = 5; $df{g} = 6 };
	lives_ok { $got = oneway_test(\%df, formula => 'y ~ g') } 'formula: a FETCH that replaces both columns does not crash';
	is_deeply( ow($got, 'g'), $want, 'formula: the columns are read as they were measured' );
}

# 2. p_adjust: each shape, a row or column replaced, shrunk, or grown
{
	my $changed = qr/^p_adjust: the data frame changed while it was being read/;
	my $in;

	$in = [ [0.01, 0.02], [0.03] ];
	tie $in->[0][0], 'OnceThen', 0.5, sub { $in->[1] = 5 };
	throws_ok { p_adjust($in) } $changed, 'AoA: a row replaced by a number croaks';

	$in = [ [0.01, 0.02], [0.03, 0.04] ];
	tie $in->[0][0], 'OnceThen', 0.5, sub { pop @{ $in->[1] } };
	throws_ok { p_adjust($in) } $changed, 'AoA: a later row that shrinks croaks';

	$in = [ [0.01, 0.02], [0.03] ];
	tie $in->[0][0], 'OnceThen', 0.5, sub { push @{ $in->[1] }, 0.04 };
	throws_ok { p_adjust($in) } $changed, 'AoA: a later row that grows croaks';

	$in = [ [0.01, 0.02], [0.03] ];
	tie $in->[0][0], 'OnceThen', 0.5, sub { @$in = () };
	throws_ok { p_adjust($in) } $changed, 'AoA: the frame emptied croaks';

	$in = [ { a => 0.01, b => 0.02 }, { a => 0.03, b => 0.04 } ];
	tie $in->[0]{a}, 'OnceThen', 0.5, sub { delete $in->[0]{b}; delete $in->[1]{a} };
	throws_ok { p_adjust($in) } $changed, 'AoH: keys deleted from this row and a later one croak';

	$in = { a => [0.01, 0.02], b => [0.03, 0.04] };
	tie $in->{a}[0], 'OnceThen', 0.5, sub { $in->{b} = 5 };
	throws_ok { p_adjust($in) } $changed, 'HoA: a later column replaced by a number croaks';

	$in = { a => [0.01, 0.02], b => [0.03, 0.04] };
	tie $in->{a}[0], 'OnceThen', 0.5, sub { delete $in->{b} };
	my $got;
	lives_ok { $got = p_adjust($in) } 'HoA: a later column deleted does not crash';
	is_deeply( $got, p_adjust({ a => [0.5, 0.02], b => [0.03, 0.04] }), 'HoA: it is read as it was measured' );

	$in = { r1 => { a => 0.01, b => 0.02 }, r2 => { a => 0.03, b => 0.04 } };
	tie $in->{r1}{a}, 'OnceThen', 0.5, sub { delete $in->{r2}; delete $in->{r1}{b} };
	lives_ok { $got = p_adjust($in) } 'HoH: a row and a key deleted do not crash';
	is_deeply( $got, p_adjust({ r1 => { a => 0.5, b => 0.02 }, r2 => { a => 0.03, b => 0.04 } }),
		'HoH: they are read as they were measured' );

	# a FETCH that changes nothing is read as an untied frame is
	$in = [ [0.01, 0.02], [0.03] ];
	tie $in->[0][0], 'OnceThen', 0.01, sub { };
	is_deeply( p_adjust($in), p_adjust([ [0.01, 0.02], [0.03] ]), 'AoA: an inert tied cell adjusts as a plain one' );
	$in = { r1 => { a => 0.01, b => 0.02 }, r2 => { a => 0.03 } };
	tie $in->{r1}{a}, 'OnceThen', 0.01, sub { };
	is_deeply( p_adjust($in), p_adjust({ r1 => { a => 0.01, b => 0.02 }, r2 => { a => 0.03 } }),
		'HoH: an inert tied cell adjusts as a plain one' );
}

# 3. Functions that held a borrowed row, column, cell or key across user code:
#    a tied cell's FETCH or a filter callback that deleted it left them reading
#    freed memory.  These cases are the 0.341 sweep's; most corrupted silently
#    and showed only under valgrind, but write_table's AoA and HoH cases
#    segfaulted, and group_by's died "panic: attempt to copy freed scalar" or
#    "Bizarre copy of ARRAY".  Each is now read as it was when it was taken,
#    or croaks.
{
	my $dir = tempdir(CLEANUP => 1);
	my $n = 0;
	my $file = sub { $n++; return "$dir/w$n.$_[0]" };
	for my $ext (qw(csv tex xlsx)) {
		my $d = [ [qw(h1 h2 h3)], [1, 2, 3], [4, 5, 6] ];
		tie $d->[1][0], 'OnceThen', 1, sub { $d->[1] = undef };
		lives_ok { write_table($d, $file->($ext), quiet => 1) } "write_table AoA .$ext: a FETCH that drops its own row";
		my $h = { a => [1, 2, 3], b => [4, 5, 6] };
		{
			package OnSecond;	# a HoA's cells are read twice, and the second read is the write
			sub TIESCALAR { my ($c, $v, $code) = @_; return bless { v => $v, code => $code, n => 0 }, $c }
			sub FETCH { my $s = shift; $s->{code}->() if ++$s->{n} == 2; return $s->{v} }
		}
		tie $h->{a}[0], 'OnSecond', 1, sub { delete $h->{b} };
		lives_ok { write_table($h, $file->($ext), quiet => 1) } "write_table HoA .$ext: a FETCH that deletes another column";
		my %hoh = (r1 => { a => 1 });
		tie $hoh{r2}, 'Thrice', 5;
		{
			package Thrice;	# a hash ref twice, then a number: the shape pass saw a row
			sub TIESCALAR { my ($c, $v) = @_; return bless { v => $v, n => 0 }, $c }
			sub FETCH { my $s = shift; return ++$s->{n} <= 2 ? { a => 2 } : $s->{v} }
		}
		eval { write_table(\%hoh, $file->($ext), quiet => 1, row_names => 'nm') };
		like( $@, qr/^$|the data frame changed while it was being written|Mixed data types/,
			"write_table HoH .$ext: a row that stops being one croaks rather than crash" );
	}

	my @x = (1 .. 10);
	my $y = [ 2, 4, 5, 4, 5, 7, 8, 9, 10, 12 ];
	my $want_r = cor(\@x, [ @$y ]);
	my $yy = [ 0, @$y[1 .. 9] ];
	tie $yy->[0], 'OnceThen', 2, sub { undef $yy };
	is( cor(\@x, $yy), $want_r, 'cor: a FETCH that frees y reads y as it was' );
	$yy = [ 0, @$y[1 .. 9] ];
	tie $yy->[0], 'OnceThen', 2, sub { undef $yy };
	is( cov(\@x, $yy), cov(\@x, [ @$y ]), 'cov: the same' );
	$yy = [ 0, @$y[1 .. 9] ];
	tie $yy->[0], 'OnceThen', 2, sub { undef $yy };
	is_deeply( cor_test(\@x, $yy), cor_test(\@x, [ @$y ]), 'cor_test: the same' );
	my $xx = [ 0, 2 .. 10 ];
	tie $xx->[0], 'OnceThen', 1, sub { push @$xx, (1) x 100_000; push @$yy, (1) x 100_000 };
	$yy = [ @$y ];
	is_deeply( cor_test($xx, $yy), cor_test(\@x, [ @$y ]), 'cor_test: a FETCH on x that grows y reads both as measured' );
	my $m = [ map { [ $_, $_ ** 2, sin $_ ] } 1 .. 6 ];
	my $want_m = cor([ map { [@$_] } @$m ]);
	tie $m->[0][0], 'OnceThen', 1, sub { splice(@$m, 1) };
	is_deeply( cor($m), $want_m, 'cor matrix: a FETCH that splices the rows away reads them as they were' );

	my $df = [ map { { g => 'a', v => $_ } } 1 .. 5 ];
	tie $df->[0]{g}, 'OnceThen', 'a', sub { @$df = () };
	is_deeply( agg($df, by => 'g', agg => { v => 'sum' }), [ { g => 'a', v => 15 } ], 'agg AoH: a FETCH that empties the frame' );
	my $hoa = { g => [1, 1, 2, 2], v => [1, 2, 3, 4] };
	tie $hoa->{v}[0], 'OnceThen', 1, sub { delete $hoa->{v}; delete $hoa->{g} };
	is_deeply( agg($hoa, by => 'g', agg => { v => 'sum' }), agg({ g => [1, 1, 2, 2], v => [1, 2, 3, 4] }, by => 'g', agg => { v => 'sum' }),
		'agg HoA: a FETCH that deletes the columns' );

	my $want_g = { a => [1 .. 5] };
	$df = [ map { { g => 'a', v => $_, f => 1 } } 1 .. 5 ];
	is_deeply( group_by($df, 'v', 'g', { f => sub { @$df = (); 1 } }), { a => [1] },
		'group_by AoH: a filter that empties the frame keeps the row it was given' );
	$df = { map { ($_ => { g => 'a', v => $_, f => 1 }) } 1 .. 5 };
	my $got = group_by($df, 'v', 'g', { f => sub { %$df = (); 1 } });
	is_deeply( [ sort { $a <=> $b } @{ $got->{a} } ], [1 .. 5], 'group_by HoH: a filter that clears the frame reads every row as taken' );
	$df = { g => [ ('a') x 5 ], v => [1 .. 5], f => [1 .. 5] };
	is_deeply( group_by($df, 'v', 'g', { f => sub { delete $df->{$_} for qw(g v); 1 } }), $want_g,
		'group_by HoA: a filter that deletes the columns' );
	$df = { g => [1, 2, 3], v => [1, 2, 3] };
	tie $df->{g}[0], 'OnceThen', 1, sub { delete $df->{g}; delete $df->{v} };
	is_deeply( group_by($df, 'v', 'g'), { 1 => [1], 2 => [2], 3 => [3] }, 'group_by HoA: a FETCH that deletes the columns' );

	$df = { map { ($_ => { v => $_ }) } 1 .. 5 };
	$got = filter($df, sub { %$df = (); 1 });
	is( scalar keys %$got, 1, 'filter HoH: a closure that clears the frame keeps the row it was given, and the walk ends' );

	my $L = { id => [1, 2, 3], a => [10, 20, 30] };
	my $R = { id => [1, 2, 3], b => [7, 8, 9] };
	tie $L->{a}[0], 'OnceThen', 10, sub { delete $L->{a} };
	is_deeply( merge($L, $R, by => 'id'),
		merge({ id => [1, 2, 3], a => [10, 20, 30] }, { id => [1, 2, 3], b => [7, 8, 9] }, by => 'id'),
		'merge HoA: a FETCH that deletes its own column' );

	my $h = { r => { x => 1 } };
	my $i = { r => [ 'y', 0, 'z', 3 ] };
	tie $i->{r}[1], 'OnceThen', 2, sub { delete $i->{r} };
	ljoin($h, $i);
	is_deeply( $h, { r => { x => 1, y => 2, z => 3 } }, 'ljoin array row: a FETCH that deletes the row' );
}

# 4. Every XSUB holds what its reference arguments refer to (xs_args_hold()).
#    A FETCH that did `undef $x` on the caller's only reference freed the
#    array being read, in any XSUB that took SvRV() of an argument.
for my $f (qw(median mean quantile)) {
	my $x = [ 0, 1 .. 2000 ];
	tie $x->[0], 'OnceThen', 5, sub { undef $x };
	no strict 'refs';
	my $want = &{"Stats::LikeR::$f"}([ 5, 1 .. 2000 ]);
	is_deeply( &{"Stats::LikeR::$f"}($x), $want, "$f: a FETCH that frees the argument reads it as it was" );
}

# The croaks above unwind through buffers on the save stack and held frames.
no_leaks_ok {
	my $in = [ [0.01, 0.02], [0.03] ];
	tie $in->[0][0], 'OnceThen', 0.5, sub { $in->[1] = 5 };
	eval { p_adjust($in) };
	my $h = { r1 => { a => 0.01, b => 0.02 }, r2 => { a => 0.03 } };
	tie $h->{r1}{a}, 'OnceThen', 0.5, sub { delete $h->{r2} };
	eval { p_adjust($h) };
} 'no leaks: p_adjust croaks on a changed frame';
no_leaks_ok {
	my $g2 = [1, 2, 4];
	my $g1 = [0, 2, 3];
	tie $g1->[0], 'OnceThen', 1.5, sub { push @$g2, 1 };
	oneway_test([ $g1, $g2 ]);
	oneway_test({ a => $g1, b => $g2 });
} 'no leaks: oneway_test holds its groups';

done_testing();
