#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

my %vars = (
   ONE => 1,
   TWO => 2,
   RECUR => '$ONE + $TWO',
   HERE => "X",
);

my $where;

package TestParser {
   use base qw( Parser::MGC );

   sub parse
   {
      my $self = shift;

      my $parts = $self->sequence_of( sub {
         $self->any_of(
            sub { my ( $varname ) = ( $self->expect( qr/\$(\w+)/ ) )[1];
                  $self->include_string( $vars{$varname} ) },
            sub { my $ret = $self->substring_before( '$' );
                  $where = [ $self->where ] if $ret eq "X";
                  return $ret },
         )
      } );
      return join "", @$parts;
   }
}

my $parser = TestParser->new;

# basic recursion using ->include_string
{
   is( $parser->from_string( q(No vars here) ), "No vars here", 'No vars' );
   is( $parser->from_string( q(Simple $ONE var) ), "Simple 1 var", 'A var' );
   is( $parser->from_string( q(Recursive $RECUR here) ), "Recursive 1 + 2 here", 'Recursive var' );
}

# ->where position reporting
{
   is( $parser->from_string( q(Position $HERE) ), "Position X", 'Result of $HERE test' );
   is( $where, [ 1, 1, "X" ], 'Position during $HERE' );
}

done_testing;
