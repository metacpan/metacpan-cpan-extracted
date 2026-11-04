#!/usr/bin/env perl
# A tied cell whose FETCH frees, grows or empties the container being read,
# found by the 2026-11-03 audit and fixed in 0.3414.  Each case used to read
# freed memory -- valgrind's "Invalid read" or "Invalid write" on every one, a
# segfault or a perl panic on some -- or to leak when the FETCH died.
#
# 1. median() of two arrays: a FETCH in the first that grew the second wrote
#    past the buffer the counting pass sized (the 256-NV stack buffer, for a
#    small call); one that shrank it left slots unwritten.  Both now croak.
# 2. hoa2aoh(), hoa2hoh(): the columns, and hoa2hoh's key column, were
#    borrowed, and a FETCH that deleted them left the rows reading freed
#    arrays ("panic: attempt to copy freed scalar", or a segfault).
# 3. add_data(): neither the row read from the second argument nor the row
#    written into the first was held, so a FETCH that cleared either hash
#    segfaulted.
# 4. vals(), avals(), sample(\@a): AvARRAY of the column or array was read once,
#    and a FETCH that pushed onto it moved the block from under the copy.
#    vals() and avals() also set the result's fill only after the loop, so a
#    FETCH that died leaked every copy made so far.
# 5. sample(\%h): a FETCH that rebuilt the hash freed the entries still to be
#    copied, and the entry table leaked when a FETCH died.
# 6. scale() of a matrix, prcomp(): the row in hand was borrowed across its
#    cells' FETCHes.
# 7. matrix(): the result and the row table were built outside the save and
#    tmps stacks, so a FETCH that died leaked the half-built matrix.
#
# Each run here is also clean under valgrind; that is how the defects were
# found and how the fixes were checked.  The cases are this module's own: R
# and SciPy have no tied cells.

require 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::Exception;
use Test::LeakTrace 'no_leaks_ok';
use Stats::LikeR qw(median hoa2aoh hoa2hoh add_data vals avals sample scale prcomp matrix);

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
# A tied scalar whose FETCH dies.
{
	package Dies;
	sub TIESCALAR { return bless {}, shift }
	sub FETCH { die "FETCH died\n" }
	sub STORE {}
}

# 1. median()
{
	my @a = (1, 2, 3);
	my @b = (4, 5, 6);
	tie $a[0], 'OnceThen', 1, sub { push @b, (1) x 5000 };
	throws_ok { median(\@a, \@b) } qr/changed between the counting pass and the value pass/,
		'median: a FETCH that grows a later array croaks rather than writing past the buffer';
	@a = (1, 2, 3);
	@b = (4, 5, 6);
	untie $a[0];
	tie $a[0], 'OnceThen', 1, sub { @b = (4) };
	throws_ok { median(\@a, \@b) } qr/changed between the counting pass and the value pass/,
		'median: a FETCH that shrinks a later array croaks rather than reading unwritten slots';
	is(median([1, 2, 3], [4, 5, 6]), 3.5, 'median of two plain arrays is unchanged');
}

# 2. hoa2aoh(), hoa2hoh()
{
	my %h = (a => [1, 2, 3], b => [4, 5, 6]);
	tie $h{$_}[0], 'OnceThen', 9, sub { %h = () } for qw(a b);
	my $r;
	lives_ok { $r = hoa2aoh(\%h) } 'hoa2aoh: a FETCH that empties the frame does not read freed columns';
	is(scalar @$r, 3, 'hoa2aoh: the rows are read from the columns as they were');

	%h = (k => [qw(x y z)], b => [4, 5, 6]);
	tie $h{b}[0], 'OnceThen', 9, sub { %h = () };
	lives_ok { $r = hoa2hoh(\%h, 'k') } 'hoa2hoh: a FETCH that empties the frame does not read freed columns';
	is_deeply([sort keys %$r], [qw(x y z)], 'hoa2hoh: every row is built');

	%h = (k => [qw(x y z)], b => [4, 5, 6]);
	tie $h{b}[1], 'OnceThen', 9, sub { delete $h{k} };
	lives_ok { $r = hoa2hoh(\%h, 'k') } 'hoa2hoh: a FETCH that deletes the key column does not read it freed';
	is_deeply([sort keys %$r], [qw(x y z)], 'hoa2hoh: the key column is read as it was');
}

# 3. add_data()
{
	my %h = (r => { a => 1 });
	my %i = (r => { a => 2, b => 3 });
	tie $i{r}{a}, 'OnceThen', 2, sub { %i = (); %h = () };
	lives_ok { add_data(\%h, \%i) } 'add_data: a FETCH that clears both hashes does not write into a freed row';

	%h = (r => [1]);
	%i = (r => [2, 3]);
	tie $i{r}[0], 'OnceThen', 2, sub { %i = () };
	lives_ok { add_data(\%h, \%i) } 'add_data: a FETCH that clears the source does not read a freed row';

	no_leaks_ok { my %t = (r => { a => 1 }); add_data(\%t, { r => { b => 2 }, s => { c => 3 } }) }
		'add_data: no leak when it makes a new hash row';
	no_leaks_ok { my @t; add_data(\@t, [[1, 2], [3]]) } 'add_data: no leak when it makes a new array row';
	throws_ok { my @t; add_data(\@t, { '1e18' => { a => 1 } }) } qr/too many to hold/,
		'add_data: an index no array can reach croaks rather than exiting';
}

# 4. vals(), avals(), sample(\@a)
{
	my @g = (1 .. 4);
	tie $g[1], 'OnceThen', 2, sub { push @g, 1 .. 100_000 };
	my $r;
	lives_ok { $r = vals({ x => \@g }, 'x') } 'vals: a FETCH that grows the column does not read the old block';
	is_deeply([ @$r[0 .. 3] ], [1, 2, 3, 4], 'vals: and the cells come out as they are');
	@g = (1 .. 4);
	untie $g[1];
	tie $g[1], 'OnceThen', 2, sub { @g = () };
	lives_ok { $r = vals({ x => \@g }, 'x') } 'vals: a FETCH that empties the column does not read freed cells';
	is(scalar @$r, 4, 'vals: the result keeps the length measured');
	@g = (1 .. 4);
	untie $g[1];
	tie $g[1], 'OnceThen', 2, sub { push @g, 1 .. 100_000 };
	my @ar;
	lives_ok { @ar = avals({ x => \@g }, 'x') } 'avals: a FETCH that grows the column does not read the old block';

	my @d = (1 .. 4);
	tie $d[2], 'Dies';
	no_leaks_ok { eval { vals({ x => \@d }, 'x') } } 'vals: no leak when a FETCH dies';
	no_leaks_ok { eval { my @x = avals({ x => \@d }, 'x') } } 'avals: no leak when a FETCH dies';

	my @s = (1 .. 50);
	tie $s[1], 'OnceThen', 2, sub { push @s, 1 .. 100_000 };
	lives_ok { $r = sample(\@s, 50) } 'sample(\@a): a FETCH that grows the array does not read the old block';
	is(scalar @$r, 50, 'sample(\@a): every draw is returned');
}

# 5. sample(\%h)
{
	my %h = map { ("k$_" => $_) } 1 .. 50;
	tie $h{k1}, 'OnceThen', 1, sub { %h = map { ("n$_" => $_) } 1 .. 5000 };
	my $r;
	lives_ok { $r = sample(\%h, 50) } 'sample(\%h): a FETCH that rebuilds the hash does not read freed entries';
	is(scalar keys %$r, 50, 'sample(\%h): every key drawn is returned');
	my %d = map { ("k$_" => $_) } 1 .. 50;
	tie $d{k1}, 'Dies';
	no_leaks_ok { eval { sample(\%d, 50) } } 'sample(\%h): no leak when a FETCH dies';
}

# 6. scale() and prcomp() of a matrix
{
	my @m = ([1, 2], [3, 4], [5, 7]);
	tie $m[1][0], 'OnceThen', 3, sub { @m = () };
	eval { scale(\@m) };
	pass('scale: a FETCH that empties the matrix does not read the freed row');
	my @p = map { [$_, $_ * $_ % 7, $_ % 3] } 1 .. 10;
	tie $p[3][0], 'OnceThen', 4, sub { @p = () };
	eval { prcomp(\@p) };
	pass('prcomp: a FETCH that empties the frame does not read the freed row');
}

# 7. matrix()
{
	my @v = (1 .. 200);
	tie $v[199], 'Dies';
	no_leaks_ok { eval { matrix(\@v, 2) } } 'matrix: no leak when a FETCH dies';
	no_leaks_ok { matrix([1 .. 6], 2) } 'matrix: no leak on a plain call';
}

done_testing();
