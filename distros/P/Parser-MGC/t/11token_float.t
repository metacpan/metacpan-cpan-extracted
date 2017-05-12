#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

package TestParser;
use base qw( Parser::MGC );

sub parse
{
   my $self = shift;

   return $self->token_float;
}

package main;

my $parser = TestParser->new;

# We're going to be testing floating point values.
sub approx
{
   my ( $got, $exp, $name ) = @_;

   ok( abs( $got - $exp ) < 1E-12, $name ) or
      diag( "Expected approximately $exp, got $got" );
}

approx( $parser->from_string( "123.0" ), 123,    'Decimal integer' );
approx( $parser->from_string( "0.0" ),     0,    'Zero' );
approx( $parser->from_string( "12." ),    12,    'Trailing DP' );
approx( $parser->from_string( ".34" ),     0.34, 'Leading DP' );
approx( $parser->from_string( "8.9" ),     8.9,  'Infix DP' );

approx( $parser->from_string( "-4.0" ),   -4,    'Negative decimal' );

approx( $parser->from_string( "1E0" ),     1, 'Scientific without DP' );
approx( $parser->from_string( "2.0E0" ),   2, 'Scientific with DP' );
approx( $parser->from_string( "3.E0" ),    3, 'Scientific with trailing DP' );
approx( $parser->from_string( ".4E1" ),    4, 'Scientific with leading DP' );
approx( $parser->from_string( "50E-1" ),   5, 'Scientific with negative exponent without DP' );
approx( $parser->from_string( "60.0E-1" ), 6, 'Scientific with DP with negative exponent' );

approx( $parser->from_string( "1e0" ), 1, 'Scientific with lowercase e' );

done_testing;
