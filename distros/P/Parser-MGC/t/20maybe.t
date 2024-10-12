#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

my $diemsg;

package TestParser {
   use base qw( Parser::MGC );

   sub parse
   {
      my $self = shift;

      $self->maybe( sub {
         $self->die( $diemsg ) if $diemsg;
         $self->token_ident;
      } ) || $self->token_int;
   }
}

package TestParser2 {
   use base qw( Parser::MGC );

   sub parse
   {
      my $self = shift;
      $self->maybe( 'token_ident' ) || $self->token_int;
   }
}

my $parser = TestParser->new;

is( $parser->from_string( "hello" ), "hello", '"hello"' );
is( $parser->from_string( "123" ), 123, '"123"' );

$diemsg = "Now have to fail";
is( dies { $parser->from_string( "456" ) },
   qq[Now have to fail on line 1 at:\n] .
   qq[456\n] .
   qq[^\n],
   'Exception from ->die failure' );

is( TestParser2->new->from_string( "hello" ), "hello", '"hello" as method name' );

done_testing;
