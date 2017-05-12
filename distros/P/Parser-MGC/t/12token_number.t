#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

package TestParser;
use base qw( Parser::MGC );

sub parse
{
   my $self = shift;

   return $self->token_number;
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

is( $parser->from_string( "123" ), 123, 'Decimal integer' );
approx( $parser->from_string( "123.0" ), 123,    'Decimal integer' );
approx( $parser->from_string( "0.0" ),     0,    'Zero' );
approx( $parser->from_string( "12." ),    12,    'Trailing DP' );
approx( $parser->from_string( ".34" ),     0.34, 'Leading DP' );
approx( $parser->from_string( "8.9" ),     8.9,  'Infix DP' );

ok( !eval { $parser->from_string( "hello" ) }, '"hello" fails' );

done_testing;
