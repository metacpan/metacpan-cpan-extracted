#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

package TestParser;
use base qw( Parser::MGC );

sub parse
{
   my $self = shift;

   # Some slight cheating here
   pos( $self->{str} ) = length( $self->{str} );

   return [ split ' ', $self->{str} ];
}

package main;

my $parser = TestParser->new;

isa_ok( $parser, "TestParser", '$parser' );
isa_ok( $parser, "Parser::MGC", '$parser' );

my $tokens = $parser->from_string( "1 2 3" );

is_deeply( $tokens, [ 1, 2, 3 ], '->from_string' );

$tokens = $parser->from_file( \*DATA );

is_deeply( $tokens, [ 4, 5, 6 ], '->from_file(\*DATA)' );

done_testing;

__DATA__
4 5 6
