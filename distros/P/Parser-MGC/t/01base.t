#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

my $STARTED;
my $ENDED;

package TestParser {
   use base qw( Parser::MGC );

   sub on_parse_start
   {
      $STARTED++;
   }

   sub on_parse_end
   {
      $ENDED = $_[1];
   }

   sub parse
   {
      my $self = shift;

      # Some slight cheating here
      pos( $self->{str} ) = length( $self->{str} );

      return [ split ' ', $self->{str} ];
   }
}

my $parser = TestParser->new;

isa_ok( $parser, "TestParser", '$parser' );
isa_ok( $parser, "Parser::MGC", '$parser' );

# ->from_string
{
   my $tokens = $parser->from_string( "1 2 3" );

   is_deeply( $tokens, [ 1, 2, 3 ], '->from_string' );

   ok( $STARTED, '->on_parse_start was invoked' );
   is( $ENDED, $tokens, '->on_parse_end was invoked on result' );
}

# ->from_file
{
   my $tokens = $parser->from_file( \*DATA );

   is_deeply( $tokens, [ 4, 5, 6 ], '->from_file(\*DATA)' );
}

done_testing;

__DATA__
4 5 6
