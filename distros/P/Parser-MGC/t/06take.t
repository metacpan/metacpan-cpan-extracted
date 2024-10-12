#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

package TestParser {
   use base qw( Parser::MGC );

   sub parse
   {
      my $self = shift;

      # Some gut-wrenching to make the test pass
      [ $self->take( 5 ), $self->take( 5 ), $self->take( length( $self->{str} ) - pos( $self->{str} ) ) ]
   }
}

my $parser = TestParser->new;

is( $parser->from_string( "Hello There" ),
   [ "Hello", " Ther", "e" ],
   '"Hello There"' );

done_testing;
