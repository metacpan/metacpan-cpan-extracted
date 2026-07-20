#!/usr/bin/env perl
require 5.010;
use warnings FATAL => 'all';
use Stats::LikeR;
use Test::Exception; # dies_ok
use Test::More;
use Test::LeakTrace 'no_leaks_ok';

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

# 9. No memory leaks across the by-name, default, omit and against paths.
# Test::LeakTrace reports Devel::Cover's instrumentation SVs as leaks, so skip
# the leak checks (which are the last tests here) when running under coverage.
if ($INC{'Devel/Cover.pm'}) { done_testing(); exit 0 }
no_leaks_ok { cfilter( \%hoa, 'keep' => [ 'x', 'y' ] ) } 'no leaks: keep by name';
no_leaks_ok { cfilter( \%hoa, 'remove' => qr/(?:step|z)/ ) } 'no leaks: remove by regex';
no_leaks_ok { cfilter( \%hoa, 'keep' => sub { 1 } ) } 'no leaks: default predicate (sees undef)';
no_leaks_ok { cfilter( \%hoa, 'keep' => sub { sd( $_[0] ) == 0 }, 'na' => 'omit' ) } 'no leaks: na=omit';
no_leaks_ok { cfilter( \%corr, 'keep' => sub { cor( $_[0], $_[1] ) > 0 }, 'against' => 'a' ) } 'no leaks: against';
done_testing();
