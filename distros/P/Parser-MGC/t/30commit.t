#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

package TestParser {
   use base qw( Parser::MGC );

   sub parse
   {
      my $self = shift;

      $self->any_of(
         sub { $self->token_int },
         sub {
            $self->scope_of( "(",
               sub {
                  $self->commit;
                  $self->token_string;
               },
               ")" );
         }
      );
   }
}

package IntStringPairsParser {
   use base qw( Parser::MGC );

   sub parse
   {
      my $self = shift;

      $self->sequence_of( sub {
         my $int = $self->token_int;
         $self->commit;

         my $str = $self->token_string;

         [ $int, $str ];
      } );
   }
}

my $parser = TestParser->new;

is( $parser->from_string( "123" ), 123, '"123"' );
is( $parser->from_string( '("hi")' ), "hi", '("hi")' );

is( dies { $parser->from_string( "(456)" ) },
   qq[Expected string delimiter on line 1 at:\n].
   qq[(456)\n].
   qq[ ^\n],
   'Exception from "(456)" failure' );

$parser = IntStringPairsParser->new;

is( $parser->from_string( "1 'one' 2 'two'" ),
   [ [ 1, "one" ], [ 2, "two" ] ],
   "1 'one' 2 'two'" );

is( dies { $parser->from_string( "1 'one' 2" ) },
   qq[Expected string on line 1 at:\n].
   qq[1 'one' 2\n].
   qq[         ^\n],
   'Exception from 1 \'one\' 2 failure' );

done_testing;
