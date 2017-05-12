#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More tests => 10;
use Moose::Util::TypeConstraints;
use MooseX::Types::Data::GUID qw/GUID/;

for my $key ( GUID, 'Data::GUID' ){
  if(my $constraint = find_type_constraint($key) ){
    isa_ok( $constraint, "Moose::Meta::TypeConstraint" );
    if ( $constraint->has_coercion ){
      ok(1, 'has coercion');
      my $coercion = $constraint->coercion;
      ok( $coercion->has_coercion_for_type('Str'), 'has coercion for Str');
      my $original_str = 'C6A9FE9A-72FE-11DD-B3B4-B2EC1DADD46B';
      if( my $guid = $coercion->coerce($original_str) ){
        isa_ok($guid, 'Data::GUID');
        is($guid->as_string, $original_str, 'Same GUID was built');
      }
    } else {
      ok(0, 'Failed to find type coercion');
    }
  } else {
    ok(0, "Failed to find type constraint '${key}'");
  }
}
