#!/usr/bin/env perl
require 5.010;
use warnings FATAL => 'all';
use Stats::LikeR;
use Test::Exception; # dies_ok
use Test::More;
use Test::LeakTrace 'no_leaks_ok';

# hoh2hoa turns a hash of hashes (outer key = row, inner key = column) into a
# hash of arrays (key = column, array = that column's values down the rows).
# Rows are emitted in sorted outer-key order, the columns are the union of every
# inner key, and a missing key or undef cell becomes the fill value (undef by
# default, overridable with undef.val).

# 1. hoh2hoa is defined and returns a hash of arrays.
ok( defined &Stats::LikeR::hoh2hoa, 'hoh2hoa is defined in Stats::LikeR' );
my %square = ( 'r1' => { 'a' => 1, 'b' => 2 }, 'r2' => { 'a' => 3, 'b' => 4 } );
my $hoa = hoh2hoa( \%square );
is( ref $hoa, 'HASH', 'hoh2hoa returns a hash ref' );
is( ref $hoa->{'a'}, 'ARRAY', 'each column maps to an array ref' );
is_deeply( [ sort keys %$hoa ], [ 'a', 'b' ], 'keys are the union of the inner keys' );

# 2. Rows come out in sorted outer-key order, identically for every column.
is_deeply( $hoa->{'a'}, [ 1, 3 ], 'column a follows the sorted row order (r1, r2)' );
is_deeply( $hoa->{'b'}, [ 2, 4 ], 'column b follows the same row order' );

# 3. Row order is the sorted outer keys regardless of how the hash was built.
my %scrambled = ( 'c' => { 'x' => 3 }, 'a' => { 'x' => 1 }, 'b' => { 'x' => 2 } );
is_deeply( hoh2hoa( \%scrambled )->{'x'}, [ 1, 2, 3 ], 'rows are ordered by sorted outer key' );

# 4. Ragged rows: the column set is the union, gaps default to undef.
my %ragged = ( 'r1' => { 'a' => 1, 'b' => 2 }, 'r2' => { 'a' => 3, 'c' => 9 } );
my $rg = hoh2hoa( \%ragged );
is_deeply( [ sort keys %$rg ], [ 'a', 'b', 'c' ], 'union spans keys missing from some rows' );
is_deeply( $rg->{'a'}, [ 1, 3 ], 'a is present in both rows' );
is( $rg->{'b'}[0], 2, 'b is present for r1' );
ok( !defined $rg->{'b'}[1], 'b missing in r2 defaults to undef' );
ok( !defined $rg->{'c'}[0], 'c missing in r1 defaults to undef' );
is( $rg->{'c'}[1], 9, 'c is present for r2' );
is( scalar( @{ $rg->{'a'} } ), scalar( @{ $rg->{'c'} } ), 'every column has one entry per row' );

# 5. undef.val overrides the fill for both missing keys and explicit undef cells.
my %withundef = ( 'r1' => { 'a' => 1, 'b' => undef }, 'r2' => { 'a' => 2, 'b' => 5 } );
my $na = hoh2hoa( \%withundef, 'undef.val' => 'NA' );
is( $na->{'b'}[0], 'NA', 'an explicit undef cell is filled by undef.val' );
is( $na->{'b'}[1], 5, 'a defined cell is preserved' );
my $rg2 = hoh2hoa( \%ragged, 'undef.val' => 'NA' );
is( $rg2->{'b'}[1], 'NA', 'a missing key is filled by undef.val' );
is( $rg2->{'c'}[0], 'NA', 'a missing key is filled by undef.val' );
# 0 and the empty string are real fill values, not "no value".
is( hoh2hoa( \%ragged, 'undef.val' => 0 )->{'b'}[1], 0, 'undef.val => 0 fills with 0' );
is( hoh2hoa( \%ragged, 'undef.val' => '' )->{'b'}[1], '', q{undef.val => '' fills with the empty string} );
# undef.val => undef is the same as the default.
ok( !defined hoh2hoa( \%ragged, 'undef.val' => undef )->{'b'}[1], 'undef.val => undef keeps the undef default' );

# 6. The default leaves an explicit undef as undef.
ok( !defined hoh2hoa( \%withundef )->{'b'}[0], 'explicit undef stays undef under the default fill' );

# 7. row.names adds a column of the sorted row labels, aligned with the data.
my %labelled = ( 'beta' => { 'v' => 2 }, 'alpha' => { 'v' => 1 } );
my $rn = hoh2hoa( \%labelled, 'row.names' => 'id' );
is_deeply( $rn->{'id'}, [ 'alpha', 'beta' ], 'row.names column holds the sorted labels' );
is_deeply( $rn->{'v'}, [ 1, 2 ], 'data columns follow the same sorted-row order' );
is_deeply( [ sort keys %$rn ], [ 'id', 'v' ], 'row.names adds exactly one extra column' );

# 8. Empty input is not an error: it yields an empty hash of arrays.
is_deeply( hoh2hoa( {} ), {}, 'empty hash of hashes yields an empty hash of arrays' );
is_deeply( hoh2hoa( {}, 'row.names' => 'id' ), { 'id' => [] }, 'empty input with row.names gives an empty label column' );

# 9. An empty inner hash is a valid (all-gaps) row.
my $sparse = hoh2hoa( { 'r1' => { 'a' => 1 }, 'r2' => {} } );
is( $sparse->{'a'}[0], 1, 'present cell kept' );
ok( !defined $sparse->{'a'}[1], 'a row with no keys is all gaps (undef)' );

# 10. Bad inputs die rather than returning garbage.
dies_ok { hoh2hoa() } 'no data dies';
dies_ok { hoh2hoa( 42 ) } 'non-reference data dies';
dies_ok { hoh2hoa( [ 1, 2, 3 ] ) } 'array ref (not a hash of hashes) dies';
dies_ok { hoh2hoa( { 'r1' => [ 1, 2 ] } ) } 'hash of arrays (values not hash refs) dies';
dies_ok { hoh2hoa( { 'r1' => { 'a' => 1 } }, 'undef.val' ) } 'an option without a value dies (odd args)';
dies_ok { hoh2hoa( { 'r1' => { 'a' => 1 } }, 'bogus' => 1 ) } 'unknown option dies';
dies_ok { hoh2hoa( { 'r1' => { 'a' => 1 } }, 'row.names' => [ 1 ] ) } 'row.names must be a string, not a ref';
dies_ok { hoh2hoa( { 'r1' => { 'a' => 1, 'id' => 5 } }, 'row.names' => 'a' ) } 'row.names colliding with a real column dies';

# 11. No memory leaks across the conversion, fill, and row-names paths.
no_leaks_ok { hoh2hoa( \%ragged ) } 'no leaks: basic conversion' unless $INC{'Devel/Cover.pm'};
no_leaks_ok { hoh2hoa( \%ragged, 'undef.val' => 'NA' ) } 'no leaks: undef.val fill' unless $INC{'Devel/Cover.pm'};
no_leaks_ok { hoh2hoa( \%labelled, 'row.names' => 'id' ) } 'no leaks: row.names column' unless $INC{'Devel/Cover.pm'};
done_testing();
