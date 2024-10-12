#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

my @positions;
my @wheres;

my $diemsg;
my $warnmsg;

package TestParser {
   use base qw( Parser::MGC );

   sub parse
   {
      my $self = shift;

      main::is( $self->pos,
         $positions[0],
         '->pos before parsing' );
      main::is( [ $self->where ],
         $wheres[0],
         '->where before parsing' );

      $self->expect( "hello" );
      main::is( $self->pos,
         $positions[1],
         '->pos during parsing' );
      main::is( [ $self->where ],
         $wheres[1],
         '->where during parsing' );

      $self->expect( qr/world/ );
      main::is( $self->pos,
         $positions[2],
         '->pos after parsing' );
      main::is( [ $self->where ],
         $wheres[2],
         '->where after parsing' );

      $self->die( $diemsg ) if $diemsg;
      $self->warn( $warnmsg ) if $warnmsg;

      return 1;
   }
}

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

{
   $diemsg = "stop here";
   like( dies { $parser->from_string( "hello\nworld" ) },
      qr/^stop here on line 2 at:\nworld\n/, 'Exception from ->die failure' );
   undef $diemsg;
}

{
   $warnmsg = "note here";
   is( warnings { $parser->from_string( "hello\nworld" ) },
      [ match(qr/^note here on line 2 at:\nworld\n/) ],
      'Warning from ->warn' );
}

done_testing;
