require 5.010;
use strict;
use warnings;
use Test::More;
use Test::Exception;
use Stats::LikeR;

# filter($df, PRED) returns a NEW dataframe (same shape) of matching rows.
# PRED is either a col()-built predicate or a coderef (row hashref in $_ / $_[0]).

# small dependency-free deep copy, just for the "original is unchanged" checks
sub snap {
	my $d = shift;
	if (ref $d eq 'ARRAY') { return [ map { +{ %$_ } } @$d ] }
	return { map { $_ => [ @{ $d->{$_} } ] } keys %$d };
}

# ---------------------------------------------------------------------------
# Array of Hashes
# ---------------------------------------------------------------------------
my $aoh = [
	{ id => 1, x => 1, grp => 'a' },
	{ id => 2, x => 5, grp => 'b' },
	{ id => 3, x => 9, grp => 'a' },
	{ id => 4, x => 5, grp => 'a' },
];
my $before = snap($aoh);

my $r = filter($aoh, col('x') > 4);
is_deeply([map {$_->{id}} @$r], [2,3,4], 'AoH: col(x) > 4');
isnt($r, $aoh, 'AoH: a new arrayref is returned');
is_deeply($aoh, $before, 'AoH: original dataframe is left unchanged');

# numeric operators
is_deeply([map {$_->{id}} @{filter($aoh, col('x') >= 5)}], [2,3,4], 'AoH: >=');
is_deeply([map {$_->{id}} @{filter($aoh, col('x') <= 5)}], [1,2,4], 'AoH: <=');
is_deeply([map {$_->{id}} @{filter($aoh, col('x') == 9)}], [3],     'AoH: ==');
is_deeply([map {$_->{id}} @{filter($aoh, col('x') != 5)}], [1,3],   'AoH: !=');
is_deeply([map {$_->{id}} @{filter($aoh, col('x') <  5)}], [1],     'AoH: <');

# operand swap: 4 < col('x')  is the same as  col('x') > 4
is_deeply([map {$_->{id}} @{filter($aoh, 4 < col('x'))}], [2,3,4], 'AoH: swapped 4 < col(x)');

# boolean composition: & | !
is_deeply([map {$_->{id}} @{filter($aoh, (col('x') > 4) & (col('x') < 9))}], [2,4],   'AoH: (x>4) & (x<9)');
is_deeply([map {$_->{id}} @{filter($aoh, (col('x') == 1) | (col('x') == 9))}], [1,3], 'AoH: (x==1) | (x==9)');
is_deeply([map {$_->{id}} @{filter($aoh, !(col('x') > 4))}], [1], 'AoH: !(x>4)');

# string operators
is_deeply([map {$_->{id}} @{filter($aoh, col('grp') eq 'a')}], [1,3,4], 'AoH: eq');
is_deeply([map {$_->{id}} @{filter($aoh, col('grp') ne 'a')}], [2],     'AoH: ne');
is_deeply([map {$_->{id}} @{filter($aoh, col('grp') gt 'a')}], [2],     'AoH: gt');

# coderef predicate (row hashref is in $_ and $_[0])
is_deeply([map {$_->{id}} @{filter($aoh, sub { $_->{x} > 4 && $_->{grp} eq 'a' })}], [3,4], 'AoH: coderef via $_');
is_deeply([map {$_->{id}} @{filter($aoh, sub { $_[0]{id} % 2 == 0 })}],               [2,4], 'AoH: coderef via $_[0]');

# keep-all and keep-none
is(scalar @{filter($aoh, col('x') > 0)},   4, 'AoH: predicate true for all keeps all');
is(scalar @{filter($aoh, col('x') > 100)}, 0, 'AoH: predicate false for all keeps none');

# missing / undef cells never match
my $aoh_missing = [ {id=>1, x=>5}, {id=>2}, {id=>3, x=>undef} ];
is_deeply([map {$_->{id}} @{filter($aoh_missing, col('x') > 0)}], [1], 'AoH: missing/undef cell excluded');

# empty frame
is_deeply(filter([], col('x') > 0), [], 'AoH: empty frame yields empty frame');

# ---------------------------------------------------------------------------
# Hash of Arrays
# ---------------------------------------------------------------------------
my $hoa = {
	id  => [1, 2, 3, 4],
	x   => [1, 5, 9, 5],
	grp => [qw(a b a a)],
};
my $hoa_before = snap($hoa);

$r = filter($hoa, col('x') > 4);
is_deeply($r->{id},  [2, 3, 4],     'HoA: col(x)>4 filters every column in parallel (id)');
is_deeply($r->{x},   [5, 9, 5],     'HoA: ... x');
is_deeply($r->{grp}, [qw(b a a)],   'HoA: ... grp');
is_deeply($hoa, $hoa_before, 'HoA: original dataframe is left unchanged');

is_deeply(filter($hoa, (col('x') > 4) & (col('grp') eq 'a'))->{id}, [3, 4], 'HoA: (x>4) & (grp eq a)');
is_deeply(filter($hoa, sub { $_->{x} == 5 })->{id}, [2, 4], 'HoA: coderef');
is_deeply(filter($hoa, col('x') > 100)->{id}, [], 'HoA: keep-none yields empty columns');

# ---------------------------------------------------------------------------
# error handling
# ---------------------------------------------------------------------------
throws_ok { filter('not a ref', col('x') > 0) }
	qr/HASH or ARRAY reference/, 'non-reference data frame croaks';
throws_ok { filter($aoh, 42) }
	qr/CODE ref or a predicate/, 'non-predicate / non-coderef croaks';
throws_ok { filter([ {a=>1}, 'oops' ], col('a') > 0) }
	qr/element 1 is not one/, 'AoH with a non-HASH element croaks';
throws_ok { filter({ a => 1 }, col('a') > 0) }
	qr/hash of arrays/, 'HoA with a non-ARRAY column croaks';

done_testing();
