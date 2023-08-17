#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use Syntax::Keyword::Match;

my $var;

sub func
{
   my ( $topic ) = @_;

   match($topic : ==) {
      case(1) { return "one" }
      case($var) { return "var" }
      case(2) { return "two" }
   }
}

$var = 1;
is( func(1), "one", 'case(1) before case($var) takes precedence' );

is( func(2), "two", 'case(2) still works' );

$var = 2;
is( func(2), "var", 'case($var) before case(2) takes precedence' );

done_testing;
