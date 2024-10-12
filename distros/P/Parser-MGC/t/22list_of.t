#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

package TestParser {
   use base qw( Parser::MGC );

   sub parse
   {
      my $self = shift;

      $self->list_of( ",", sub {
         return $self->token_int;
      } );
   }
}

package TestParser2 {
   use base qw( Parser::MGC );

   sub parse
   {
      my $self = shift;

      $self->list_of( ",", 'token_int' );
   }
}

package TestParser3 {
   use base qw( Parser::MGC );

   sub parse
   {
      my $self = shift;

      $self->list_of( ":", 'parse_inner' );
   }

   sub parse_inner
   {
      my $self = shift;

      return ( "(", $self->token_int, ")" );
   }
}

my $parser = TestParser->new;

is( $parser->from_string( "123" ), [ 123 ], '"123"' );
is( $parser->from_string( "4,5,6" ), [ 4, 5, 6 ], '"4,5,6"' );
is( $parser->from_string( "7, 8" ), [ 7, 8 ], '"7, 8"' );

# Trailing delimiter
is( $parser->from_string( "10,11,12," ), [ 10, 11, 12 ], '"10,11,12,"' );

is( TestParser2->new->from_string( "13,14" ), [ 13, 14 ], '"13,14" as method name' );

# List-context
is( TestParser3->new->from_string( "20:25" ), [qw[ ( 20 ) ( 25 ) ]], '20:25 in list context' );

done_testing;
