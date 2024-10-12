#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

package TestParser {
   use base qw( Parser::MGC );

   sub parse
   {
      my $self = shift;

      return $self->token_kw( qw( foo bar ) );
   }
}

my $parser = TestParser->new;

is( $parser->from_string( "foo" ), "foo", 'Keyword' );

is( dies { $parser->from_string( "splot" ) },
   qq[Expected any of foo, bar on line 1 at:\n] .
   qq[splot\n] .
   qq[^\n],
   'Exception from "splot" failure' );

done_testing;
