#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

package TestParser;
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

package IntStringPairsParser;
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

package main;

my $parser = TestParser->new;

is( $parser->from_string( "123" ), 123, '"123"' );
is( $parser->from_string( '("hi")' ), "hi", '("hi")' );

ok( !eval { $parser->from_string( "(456)" ) }, '"(456)" fails' );
is( $@,
   qq[Expected string delimiter on line 1 at:\n].
   qq[(456)\n].
   qq[ ^\n],
   'Exception from "(456)" failure' );

$parser = IntStringPairsParser->new;

is_deeply( $parser->from_string( "1 'one' 2 'two'" ),
           [ [ 1, "one" ], [ 2, "two" ] ],
           "1 'one' 2 'two'" );

ok( !eval { $parser->from_string( "1 'one' 2" ) }, "1 'one' 2 fails" );
is( $@,
    qq[Expected string on line 1 at:\n].
    qq[1 'one' 2\n].
    qq[         ^\n],
    'Exception from 1 \'one\' 2 failure' );

done_testing;
