#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

package TestParser;
use base qw( Parser::MGC );

sub parse
{
   my $self = shift;

   $self->sequence_of( sub {
      return $self->token_int;
   } );
}

package IntThenStringParser;
use base qw( Parser::MGC );

sub parse
{
   my $self = shift;

   [ $self->sequence_of( sub {
         return $self->token_int;
      } ),

      $self->sequence_of( sub {
         return $self->token_string;
      } ),
   ];
}

package main;

my $parser = TestParser->new;

is_deeply( $parser->from_string( "123" ), [ 123 ], '"123"' );
is_deeply( $parser->from_string( "4 5 6" ), [ 4, 5, 6 ], '"4 5 6"' );

is_deeply( $parser->from_string( "" ), [], '""' );

$parser = IntThenStringParser->new;

is_deeply( $parser->from_string( "10 20 'ab' 'cd'" ),
           [ [ 10, 20 ], [ 'ab', 'cd' ] ], q("10 20 'ab' 'cd'") );

is_deeply( $parser->from_string( "10 20" ),
           [ [ 10, 20 ], [] ], q("10 20") );

is_deeply( $parser->from_string( "'ab' 'cd'" ),
           [ [], [ 'ab', 'cd' ] ], q("'ab' 'cd'") );

done_testing;
