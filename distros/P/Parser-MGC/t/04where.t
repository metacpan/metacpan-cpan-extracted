#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

my @positions;
my @wheres;

package TestParser;
use base qw( Parser::MGC );

sub parse
{
   my $self = shift;

   main::is( $self->pos,
      $positions[0],
      '->pos before parsing' );
   main::is_deeply( [ $self->where ],
      $wheres[0],
      '->where before parsing' );

   $self->expect( "hello" );
   main::is( $self->pos,
      $positions[1],
      '->pos during parsing' );
   main::is_deeply( [ $self->where ],
      $wheres[1],
      '->where during parsing' );

   $self->expect( qr/world/ );
   main::is( $self->pos,
      $positions[2],
      '->pos after parsing' );
   main::is_deeply( [ $self->where ],
      $wheres[2],
      '->where after parsing' );

   return 1;
}

package main;

my $parser = TestParser->new;

@positions = ( 0, 5, 11 );
@wheres = (
   [ 1, 0, "hello world" ],
   [ 1, 5, "hello world" ],
   [ 1, 11, "hello world" ], );
$parser->from_string( "hello world" );

@positions = ( 0, 5, 11 );
@wheres = (
   [ 1, 0, "hello" ],
   [ 1, 5, "hello" ],
   [ 2, 5, "world" ], );
$parser->from_string( "hello\nworld" );

done_testing;
