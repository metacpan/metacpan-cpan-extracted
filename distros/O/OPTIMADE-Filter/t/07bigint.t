#!/usr/bin/perl

use Math::BigInt;
use OPTIMADE::Filter::Comparison;
use OPTIMADE::Filter::Property;
use Scalar::Util qw(blessed);
use Test::More tests => 7;

my $clause = OPTIMADE::Filter::Comparison->new( '=' );
$clause->left( OPTIMADE::Filter::Property->new( 'column' ) );
$clause->right( Math::BigInt->new( '1' ) );

my( $SQL, $values ) = $clause->to_SQL( { placeholder => '?' } );
is( $SQL, '\'column\' = ?' );
ok( $values->[0]->isa( Math::BigInt:: ) );
is( $values->[0] . '', '1' );

# Doing senseless modification

$clause = $clause->modify( sub { return $_[0] } );
ok( $clause->right->isa( Math::BigInt:: ) );
is( $clause->right . '', '1' );

# Converting Math::BigInt to string

$clause = $clause->modify( sub {
                                 return $_[0] unless blessed $_[0];
                                 return $_[0] unless $_[0]->isa( Math::BigInt );
                                 return "$_[0]";
                               } );
is( ref $clause->right, '' );
is( $clause->right, '1' );
