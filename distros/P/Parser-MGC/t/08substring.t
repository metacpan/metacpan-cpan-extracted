#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

package TestParser {
   use base qw( Parser::MGC );

   our $Nonempty;

   sub parse
   {
      my $self = shift;

      [ ( $Nonempty ? $self->nonempty_substring_before( "!" ) : $self->substring_before( "!" ) ),
        $self->expect( "!" ) ];
   }
}

my $parser = TestParser->new;

{
   is( $parser->from_string( "Hello, world!" ),
      [ "Hello, world", "!" ],
      '"Hello, world!"' );

   is( $parser->from_string( "!" ),
      [ "", "!" ],
      '"!"' );
}

{
   local $TestParser::Nonempty = 1;

   is( dies { $parser->from_string( "!" ) },
      qq[Expected to find a non-empty substring before \(\?^u:\\!\) on line 1 at:\n] .
      qq[!\n] .
      qq[^\n],
      'Exception from ->nonempty_substring_before failure' );
}

done_testing;
