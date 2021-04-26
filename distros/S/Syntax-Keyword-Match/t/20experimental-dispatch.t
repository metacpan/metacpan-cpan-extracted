#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use Syntax::Keyword::Match qw( match :experimental(dispatch) );

# code stolen from benchmark.pl
sub match_case
{
   my ( $x ) = @_;
   match( $x : eq ) {
      case( "one"   ) { return 1; }
      case( "two"   ) { return 2; }
      case( "three" ) { return 3; }
      case( "four"  ) { return 4; }
      case( "five"  ) { return 5; }
      case( "six"   ) { return 6; }
      case( "seven" ) { return 7; }
      case( "eight" ) { return 8; }
      case( "nine"  ) { return 9; }
      default         { return 0; }
   }
}

# large stringy match
{
   my $i = 0;
   my %expect = map { $_ => $i++ } qw( zero one two three four five six seven eight nine );

   is( match_case( $_ ), $expect{$_}, "match_case($_)" )
      for sort keys %expect;
}

done_testing;
