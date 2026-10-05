#!/usr/bin/env perl
require 5.010;
use warnings FATAL => 'all';
use Stats::LikeR;
use Test::Exception; # dies_ok
use Test::More;
use Test::LeakTrace 'no_leaks_ok';	# and Test::LeakTrace::count_sv(), called by its full name

# cfilter selects columns (the inner/2nd-level keys of a HoH or AoH, or the
# outer keys of a HoA) and returns the data in the same shape. The selector is
# keep => [names] / remove => [names], or keep/remove => a predicate (CODE ref
# or function name). Exactly one of keep/remove. For a predicate, undef handling
# is:
#   default          - the predicate sees EVERY cell, including undef
#   na => 'omit'     - a single-column function (sd) gets only the defined cells
#   against => 'col' - a two-column function (cor) gets ($col, $ref) over rows
#                      where BOTH are defined (pairwise complete)
# The predicate is called as $pred->($col, $name), or with against as
# $pred->($col, $ref, $name).

# Three-column table with gaps, in all three shapes. z is constant where defined
# (sd 0); y has one gap; z has two.
my %hoa = (
	'x' => [ 1, 2, 3, 4, 5 ],
	'y' => [ 2, undef, 6, 8, 10 ],
	'z' => [ 7, 7, 7, undef, undef ],
);
my @aoh = map {
	my $i = $_;
	+{ map { defined $hoa{$_}[$i] ? ( $_ => $hoa{$_}[$i] ) : () } qw(x y z) }
} 0 .. 4;
my %hoh = map { ( "r$_" => $aoh[$_] ) } 0 .. 4;

# non-constant fixture for cor() tests: cor() croaks on a constant column (its
# standard deviation is 0), so a two-column comparison must not feed it one.
# a and b are perfectly correlated; c is anti-correlated.
my %corr = ( 'a' => [ 1, 2, 3, 4, 5 ], 'b' => [ 2, 4, 6, 8, 10 ], 'c' => [ 5, 4, 3, 2, 1 ] );

# clean (gap-free) fixtures for the by-name shape tests
my %choa = ( 'x' => [ 1, 2, 3 ], 'y' => [ 4, 5, 6 ], 'z' => [ 0, 0, 0 ] );
my @caoh = ( { 'x' => 1, 'y' => 4, 'z' => 0 }, { 'x' => 2, 'y' => 5, 'z' => 0 } );
my %choh = ( 'r1' => { 'x' => 1, 'y' => 4 }, 'r2' => { 'x' => 2, 'y' => 5 } );

# shape-agnostic set of column (inner-key) names present in a result
sub cols_of {
	my $r = shift;
	my %c;
	if ( ref $r eq 'ARRAY' ) { $c{$_}++ for map { keys %$_ } @$r }
	elsif ( ( values %$r )[0] && ref( ( values %$r )[0] ) eq 'HASH' ) { $c{$_}++ for map { keys %$_ } values %$r }
	else { $c{$_}++ for keys %$r }
	return [ sort keys %c ];
}

# 1. cfilter is defined.
ok( defined &Stats::LikeR::cfilter, 'cfilter is defined in Stats::LikeR' );

# 2. keep / remove by name, all three shapes (shape preserved).
is_deeply( cfilter( \%choa, 'keep' => [ 'x', 'y' ] ), { 'x' => [ 1, 2, 3 ], 'y' => [ 4, 5, 6 ] }, 'HoA: keep by name' );
is_deeply( cfilter( \%choa, 'remove' => [ 'z' ] ), { 'x' => [ 1, 2, 3 ], 'y' => [ 4, 5, 6 ] }, 'HoA: remove by name' );
is_deeply( cfilter( \%choh, 'keep' => [ 'x' ] ), { 'r1' => { 'x' => 1 }, 'r2' => { 'x' => 2 } }, 'HoH: keep by name trims each row' );
is_deeply( cfilter( \@caoh, 'keep' => [ 'x', 'z' ] ), [ { 'x' => 1, 'z' => 0 }, { 'x' => 2, 'z' => 0 } ], 'AoH: keep by name' );
is( ref cfilter( \@caoh, 'keep' => [ 'x' ] ), 'ARRAY', 'AoH stays an array ref' );

# 3. Default predicate mode: the predicate sees EVERY cell, including undef.
{
	my ( %n, %u );
	cfilter( \%hoa, 'keep' => sub { my ( $v, $name ) = @_; $n{$name} = scalar @$v; $u{$name} = grep { !defined } @$v; 1 } );
	is_deeply( \%n, { 'x' => 5, 'y' => 5, 'z' => 5 }, 'default: predicate sees every row' );
	is_deeply( \%u, { 'x' => 0, 'y' => 1, 'z' => 2 }, 'default: undef cells are present' );
}

# 4. na => 'omit': single-column functions get only the defined cells.
{
	my %n;
	cfilter( \%hoa, 'keep' => sub { $n{ $_[1] } = scalar @{ $_[0] }; 1 }, 'na' => 'omit' );
	is_deeply( \%n, { 'x' => 5, 'y' => 4, 'z' => 3 }, 'na=omit: only defined cells passed' );
}
is_deeply( cols_of( cfilter( \%hoa, 'keep' => sub { sd( $_[0] ) == 0 }, 'na' => 'omit' ) ), [ 'z' ], 'na=omit: sd keeps the constant column z' );

# 5. against => 'col': two-column comparison, pairwise complete (defined in BOTH).
{
	my %paired;
	cfilter( \%hoa, 'keep' => sub { $paired{ $_[2] } = scalar @{ $_[0] }; 1 }, 'against' => 'x' );
	# y pairs with x on rows 0,2,3,4 => 4; z pairs on rows 0,1,2 => 3
	is_deeply( \%paired, { 'x' => 5, 'y' => 4, 'z' => 3 }, 'against: pairwise-complete row counts' );
}
is_deeply( cols_of( cfilter( \%corr, 'keep' => sub { cor( $_[0], $_[1] ) > 0.99 }, 'against' => 'a' ) ), [ 'a', 'b' ], 'against: keep columns positively correlated with a (a,b); c dropped' );

# 6. The same selection agrees across shapes (column = inner key).
is_deeply( cols_of( cfilter( \%hoh, 'keep' => sub { sd( $_[0] ) == 0 }, 'na' => 'omit' ) ), [ 'z' ], 'HoH na=omit keeps column z' );
is_deeply( cols_of( cfilter( \@aoh, 'keep' => sub { sd( $_[0] ) == 0 }, 'na' => 'omit' ) ), [ 'z' ], 'AoH na=omit keeps column z' );

# 7. Output preserves undef cells in a kept column; input is not mutated.
is_deeply( cfilter( \%hoa, 'keep' => [ 'y' ] ), { 'y' => [ 2, undef, 6, 8, 10 ] }, 'kept column keeps its undef cells' );
is_deeply( \%hoa, { 'x' => [ 1, 2, 3, 4, 5 ], 'y' => [ 2, undef, 6, 8, 10 ], 'z' => [ 7, 7, 7, undef, undef ] }, 'input is left untouched' );

# 7b. qr// selector: keep/remove columns whose NAME matches the pattern, all
#     three shapes. A bare pattern matches anywhere in the name (no anchoring).
is_deeply( cfilter( \%choa, 'keep' => qr/^[xy]$/ ), { 'x' => [ 1, 2, 3 ], 'y' => [ 4, 5, 6 ] }, 'HoA: keep by regex' );
is_deeply( cfilter( \%choa, 'remove' => qr/z/ ), { 'x' => [ 1, 2, 3 ], 'y' => [ 4, 5, 6 ] }, 'HoA: remove by regex' );
is_deeply( cols_of( cfilter( \%choh, 'keep' => qr/x/ ) ), [ 'x' ], 'HoH: keep by regex trims each row' );
is_deeply( cols_of( cfilter( \@caoh, 'remove' => qr/y/ ) ), [ 'x', 'z' ], 'AoH: remove by regex' );
# a real-world shape: drop the columns whose name contains step or bias_
{
	my %md = ( 'y' => [ 1, 2 ], 'step_1' => [ 3, 4 ], 'step_2' => [ 5, 6 ], 'bias_a' => [ 7, 8 ] );
	is_deeply( cols_of( cfilter( \%md, 'remove' => qr/(?:step|bias_)/ ) ), [ 'y' ], 'remove => qr/step|bias_/ drops the matching columns' );
}
# regex, like the by-name selector, does not inspect the data: na/against die.
dies_ok { cfilter( \%hoa, 'keep' => qr/x/, 'na' => 'omit' ) } 'na with a regex selector dies';
dies_ok { cfilter( \%hoa, 'keep' => qr/x/, 'against' => 'x' ) } 'against with a regex selector dies';
# input is left untouched.
is_deeply( \%choa, { 'x' => [ 1, 2, 3 ], 'y' => [ 4, 5, 6 ], 'z' => [ 0, 0, 0 ] }, 'regex: input is left untouched' );

# 8. Bad inputs / option misuse die.
dies_ok { cfilter( \%hoa ) } 'no keep/remove dies';
dies_ok { cfilter( \%hoa, 'keep' => [ 'x' ], 'remove' => [ 'y' ] ) } 'both keep and remove dies';
dies_ok { cfilter( \%hoa, 'keep' => [ 'nope' ] ) } 'unknown named column dies';
dies_ok { cfilter( \%hoa, 'keep' => {} ) } 'hash-ref selector dies';
dies_ok { cfilter( \%hoa, 'keep' => 'no_such_function' ) } 'unknown function name dies';
dies_ok { cfilter( \%hoa, 'bogus' => [ 'x' ] ) } 'unknown option dies';
dies_ok { cfilter( \%hoa, 'keep' => [ 'x' ], 'na' => 'omit' ) } 'na with a by-name selector dies';
dies_ok { cfilter( \%hoa, 'keep' => sub { 1 }, 'na' => 'omit', 'against' => 'x' ) } 'na together with against dies';
dies_ok { cfilter( \%hoa, 'keep' => sub { 1 }, 'na' => 'bad' ) } 'na must be keep or omit';
dies_ok { cfilter( \%hoa, 'keep' => sub { 1 }, 'against' => 'nope' ) } 'against on an unknown column dies';
dies_ok { cfilter( 42, 'keep' => [ 'x' ] ) } 'non-reference data dies';

# 8b. against on a row-major table: the reference column lines up row by row.
{
	my %paired;
	cfilter( \@aoh, 'keep' => sub { $paired{ $_[2] } = scalar @{ $_[0] }; 1 }, 'against' => 'x' );
	is_deeply( \%paired, { 'x' => 5, 'y' => 4, 'z' => 3 }, 'AoH against: pairwise-complete row counts' );
	%paired = ();
	cfilter( \%hoh, 'keep' => sub { $paired{ $_[2] } = scalar @{ $_[0] }; 1 }, 'against' => 'y' );
	is_deeply( \%paired, { 'x' => 4, 'y' => 4, 'z' => 2 }, 'HoH against: pairwise-complete row counts' );
}

# 8c. A predicate that rewrites the caller's data. Up to 0.3212 the output step
#     dereferenced the replaced row or column without checking it, and each of
#     these was a segfault; now each is the shape error the input would get.
{
	my @a = ( { 'a' => 1 }, { 'a' => 2 } );
	throws_ok { cfilter( \@a, 'keep' => sub { $a[1] = 5; 1 } ) } qr/array elements must be hash refs/, 'AoH row replaced by the predicate dies, no crash';
	my %h = ( 'x' => [1], 'y' => [2] );
	throws_ok { cfilter( \%h, 'keep' => sub { $h{'x'} = 5; 1 } ) } qr/every value must be an array ref/, 'HoA column replaced by the predicate dies, no crash';
	my %hh = ( 'r' => { 'a' => 1 }, 's' => { 'a' => 2 } );
	throws_ok { cfilter( \%hh, 'keep' => sub { $hh{'r'} = 5; 1 } ) } qr/every value must be a hash ref/, 'HoH row replaced by the predicate dies, no crash';
	# emptying the rows is not a shape error: later columns still see the rows
	# as they were when cfilter was called, and the output reflects the change.
	my @b = ( { 'a' => 1, 'b' => 2 }, { 'a' => 3, 'b' => 4 } );
	my @seen;
	is_deeply( cfilter( \@b, 'keep' => sub { push @seen, scalar @{ $_[0] }; @b = (); 1 } ), [], 'AoH emptied by the predicate gives an empty result' );
	is_deeply( \@seen, [ 2, 2 ], '... and every column was still built from the original rows' );
}

# 8d. Selecting from an AoH or HoH must not keep a mortal per cell alive until
#     the statement ends. hv_iterkeysv() makes one per key it returns, and up to
#     0.3212 the column-union and output loops called it once per cell with no
#     temps scope of their own. count_sv() counts every live SV, so calling it in
#     the same statement as cfilter() sees those mortals before they are freed,
#     and comparing with a call after the statement separates them from the
#     result. On this 2000 x 20 table, keeping one column, the old code held
#     80004 SVs beyond the result (AoH) and 82002 (HoH); with a temps scope per
#     row it held 28 and 26 (perl 5.44.0, x86_64 linux). Those are cfilter's own
#     scratch tables, a few per column, so the 1000 bound leaves 35x headroom
#     and still fails the old code by a factor of 80.
{
	my @big = map { my $i = $_; +{ map { ( "c$_" => $i ) } 1 .. 20 } } 1 .. 2000;
	my %bigh = map { ( "r$_" => $big[ $_ - 1 ] ) } 1 .. 2000;
	for my $case ( [ 'AoH', \@big ], [ 'HoH', \%bigh ] ) {
		my ( $got, $during ) = ( cfilter( $case->[1], 'keep' => [ 'c1' ] ), Test::LeakTrace::count_sv() );
		my $after = Test::LeakTrace::count_sv();
		cmp_ok( $during - $after, '<', 1000, "$case->[0] keep by name: no mortal per cell (" . ( $during - $after ) . ' SVs beyond the result, bound 1000)' );
	}
}

# 8e. cfilter leaves the caller's each() position alone. Up to 0.3212 every walk
#     of a hash called hv_iterinit(), so an each() loop in progress on the data
#     or on any of its rows started again, and saw keys twice; and a croak in
#     mid-walk left the next each() starting part-way into the hash.
{
	my $drain = sub { my $h = shift; my @k; while ( my ($k) = each %$h ) { push @k, $k } @k };
	my %wide = map { ( "k$_" => [ 1, 2, 3 ] ) } 1 .. 50;
	for my $sel ( [ 'k1' ], qr/k1/, sub { 1 } ) {
		my %seen;
		my ($first) = each %wide;
		$seen{$first}++;
		cfilter( \%wide, 'keep' => $sel );
		$seen{$_}++ for $drain->( \%wide );
		is_deeply( [ scalar keys %seen, scalar grep { $_ > 1 } values %seen ], [ 50, 0 ], 'HoA, ' . ( ref $sel ) . ' selector: each() resumes and sees every key once' );
	}
	{# the caller deleted the entry each() was on (perl frees it lazily)
		my %g = %wide;
		my ($first) = each %g;
		delete $g{$first};
		my %seen;
		cfilter( \%g, 'keep' => sub { 1 } );
		$seen{$_}++ for $drain->( \%g );
		is_deeply( [ scalar keys %seen, scalar grep { $_ > 1 } values %seen ], [ 49, 0 ], 'each() resumes after the caller deleted its current entry' );
	}
	{# the predicate deletes the entry the caller's each() is on: it is freed, so
	 # the iterator cannot be put back and is left reset, as before
		my %g = %wide;
		my ($first) = each %g;
		cfilter( \%g, 'keep' => sub { delete $g{$first}; 1 } );
		is( scalar( () = $drain->( \%g ) ), 49, 'predicate deleting the current entry leaves each() reset, not dangling' );
	}
	{
		my %g = ( ( map { ( "k$_" => [1] ) } 1 .. 20 ), 'bad' => 5 );
		eval { cfilter( \%g, 'keep' => [ 'k1' ] ) };
		# which message depends on hash order: the shape check sees one value first
		like( $@, qr/must be array refs \(HoA\)|must be an array ref/, 'a HoA with a scalar value dies' );
		is( scalar( () = $drain->( \%g ) ), 21, '... and the next each() starts at the beginning' );
	}
	{
		my @rows = map { +{ map { ( "c$_" => 1 ) } 1 .. 30 } } 1 .. 3;
		my ($first) = each %{ $rows[1] };
		my %seen = ( $first => 1 );
		cfilter( \@rows, 'keep' => [ 'c1' ] );
		$seen{$_}++ for $drain->( $rows[1] );
		is_deeply( [ scalar keys %seen, scalar grep { $_ > 1 } values %seen ], [ 30, 0 ], 'AoH: each() on a row resumes' );
	}
	{
		my %hh = map { my $r = $_; ( "r$r" => { map { ( "c$_" => $r ) } 1 .. 30 } ) } 1 .. 30;
		my ($fo) = each %hh;
		my ($fi) = each %{ $hh{'r5'} };
		my %so = ( $fo => 1 );
		my %si = ( $fi => 1 );
		cfilter( \%hh, 'keep' => sub { 1 } );
		$so{$_}++ for $drain->( \%hh );
		$si{$_}++ for $drain->( $hh{'r5'} );
		is_deeply( [ scalar( keys %so ), scalar( grep { $_ > 1 } values %so ), scalar( keys %si ), scalar( grep { $_ > 1 } values %si ) ], [ 30, 0, 30, 0 ], 'HoH: each() on the table and on a row both resume' );
	}
}

# 8f. Tied data. Up to 0.3212 a tied hash died with "hash values must be array
#     refs": cfilter tested the value it got from the tie before fetching it.
{
	require Tie::Hash;
	require Tie::Array;
	tie my %t, 'Tie::StdHash';
	%t = ( 'x' => [ 1, undef, 3 ], 'y' => [ 2, 2, 2 ] );
	is_deeply( cfilter( \%t, 'keep' => [ 'x' ] ), { 'x' => [ 1, undef, 3 ] }, 'tied HoA: keep by name' );
	is_deeply( cols_of( cfilter( \%t, 'keep' => sub { sd( $_[0] ) == 0 }, 'na' => 'omit' ) ), [ 'y' ], 'tied HoA: predicate' );
	tie my @col, 'Tie::StdArray';
	@col = ( 5, undef, 7 );
	my %n;
	cfilter( { 'a' => \@col, 'b' => [ 1, 2, 3 ] }, 'keep' => sub { $n{ $_[1] } = [ @{ $_[0] } ]; 1 } );
	is_deeply( \%n, { 'a' => [ 5, undef, 7 ], 'b' => [ 1, 2, 3 ] }, 'tied HoA column: the predicate sees its cells' );
	tie my %row, 'Tie::StdHash';
	%row = ( 'p' => 1, 'q' => 2 );
	is_deeply( cfilter( [ \%row, { 'p' => 3 } ], 'keep' => [ 'p' ] ), [ { 'p' => 1 }, { 'p' => 3 } ], 'tied AoH row: keep by name' );
	%n = ();
	cfilter( [ \%row, { 'p' => 3 } ], 'keep' => sub { $n{ $_[1] } = [ @{ $_[0] } ]; 1 }, 'na' => 'omit' );
	is_deeply( \%n, { 'p' => [ 1, 3 ], 'q' => [ 2 ] }, 'tied AoH row: the predicate sees its cells' );
	tie my @ta, 'Tie::StdArray';
	@ta = ( { 'p' => 1, 'q' => 2 }, { 'p' => 3 } );
	is_deeply( cfilter( \@ta, 'remove' => [ 'q' ] ), [ { 'p' => 1 }, { 'p' => 3 } ], 'tied AoH: remove by name' );
}

# 9. No memory leaks across the by-name, default, omit and against paths.
# Test::LeakTrace reports Devel::Cover's instrumentation SVs as leaks, so skip
# the leak checks (which are the last tests here) when running under coverage.
if ($INC{'Devel/Cover.pm'}) { done_testing(); exit 0 }
no_leaks_ok { cfilter( \%hoa, 'keep' => [ 'x', 'y' ] ) } 'no leaks: keep by name';
# The qr// is compiled outside the block on purpose: perl 5.10.0 leaks one SV
# per qr// evaluation. pp_qr() takes the package name from reg_qr_package(),
# which is a newSVpvs("Regexp"), and never releases it; the SvREFCNT_dec(pkg)
# that fixes it is in 5.10.1's pp_hot.c. A CPAN smoker on perl-5.10.0
# (x86_64-linux) failed 0.315 here with a leaked PV "Regexp", which is that SV
# and not anything cfilter() did.
my $re_step_z = qr/(?:step|z)/;
no_leaks_ok { cfilter( \%hoa, 'remove' => $re_step_z ) } 'no leaks: remove by regex';
no_leaks_ok { cfilter( \%hoa, 'keep' => sub { 1 } ) } 'no leaks: default predicate (sees undef)';
no_leaks_ok { cfilter( \%hoa, 'keep' => sub { sd( $_[0] ) == 0 }, 'na' => 'omit' ) } 'no leaks: na=omit';
no_leaks_ok { cfilter( \%corr, 'keep' => sub { cor( $_[0], $_[1] ) > 0 }, 'against' => 'a' ) } 'no leaks: against';
no_leaks_ok { cfilter( \@aoh, 'keep' => sub { 1 }, 'against' => 'x' ) } 'no leaks: AoH against';
no_leaks_ok { cfilter( \%hoh, 'remove' => [ 'z' ] ) } 'no leaks: HoH remove by name';
# Every croak after the scratch tables exist. Up to 0.3212 these were plain
# newHV()/newAV() freed only at the end, so each of these leaked them, and a
# dying predicate leaked the whole copied table.
no_leaks_ok { eval { cfilter( \%hoa, 'keep' => [ 'nope' ] ) } } 'no leaks: croak on an unknown named column';
no_leaks_ok { eval { cfilter( \%hoa, 'keep' => sub { die "no\n" } ) } } 'no leaks: predicate dies';
no_leaks_ok { eval { cfilter( \@aoh, 'keep' => sub { die "no\n" }, 'against' => 'x' ) } } 'no leaks: predicate dies under against';
no_leaks_ok { eval { cfilter( \%hoa, 'keep' => sub { 1 }, 'against' => 'nope' ) } } 'no leaks: croak on an unknown against column';
no_leaks_ok { eval { cfilter( [ { 'a' => 1 }, 5 ], 'keep' => [ 'a' ] ) } } 'no leaks: croak on a bad AoH element';
no_leaks_ok {
	my @a = ( { 'a' => 1 }, { 'a' => 2 } );
	eval { cfilter( \@a, 'keep' => sub { $a[1] = 5; 1 } ) };
} 'no leaks: croak on a row the predicate replaced';
# iter_keep(): the saved iterator holds a reference to the hash, released at the
# LEAVE that restores it; the busy, idle-with-croak and tied paths each differ.
{
	my %w = map { ( "k$_" => [ 1, 2 ] ) } 1 .. 10;
	my ($first) = each %w;
	no_leaks_ok { cfilter( \%w, 'keep' => sub { 1 } ) } 'no leaks: each() in progress on the data';
	keys %w;	# resets the iterator
	my %d = %w;
	($first) = each %d;
	delete $d{$first};
	my @present = grep { exists $d{$_} } 'k1', 'k2';	# $first may have been either; exists leaves the iterator alone
	no_leaks_ok { cfilter( \%d, 'keep' => [ $present[0] ] ) } 'no leaks: each() on a deleted entry';
	keys %d;
	tie my %t, 'Tie::StdHash';
	%t = ( 'x' => [1], 'y' => [2] );
	no_leaks_ok { cfilter( \%t, 'keep' => sub { 1 }, 'against' => 'x' ) } 'no leaks: tied HoA';
}
done_testing();
