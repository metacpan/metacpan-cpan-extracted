#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

# This "test" never fails, but prints a benchmark comparison between this
# syntax and a simple if/elsif chain

use Time::HiRes qw( gettimeofday tv_interval );
sub measure(&)
{
   my ( $code ) = @_;
   my $start = [ gettimeofday ];
   $code->();
   return tv_interval $start;
}

use Syntax::Keyword::Match 0.03 qw( match :experimental(dispatch) );

sub digit_ifelsif
{
   my ( $x ) = @_;
   if   ( $x eq "one"   ) { return 1; }
   elsif( $x eq "two"   ) { return 2; }
   elsif( $x eq "three" ) { return 3; }
   elsif( $x eq "four"  ) { return 4; }
   elsif( $x eq "five"  ) { return 5; }
   elsif( $x eq "six"   ) { return 6; }
   elsif( $x eq "seven" ) { return 7; }
   elsif( $x eq "eight" ) { return 8; }
   elsif( $x eq "nine"  ) { return 9; }
   else                   { return 0; }
}

sub digit_matchcase
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

my $COUNT = 5_000;

my $matchcase_elapsed = 0;
my $ifelsif_elapsed = 0;

# To reduce the influence of bursts of timing noise, interleave many small runs
# of each type.

foreach ( 1 .. 20 ) {
   $matchcase_elapsed += measure {
      foreach ( 1 .. $COUNT ) {
         digit_matchcase $_ for 0 .. 9;
      }
   };
   $ifelsif_elapsed += measure {
      foreach ( 1 .. $COUNT ) {
         digit_ifelsif $_ for 0 .. 9;
      }
   };
}

pass( "Benchmarked" );

if( $matchcase_elapsed > $ifelsif_elapsed ) {
   diag( sprintf "if/elsif took %.3fsec, ** this was SLOWER at %.3fsec **",
      $ifelsif_elapsed, $matchcase_elapsed );
}
else {
   my $speedup = ( $ifelsif_elapsed - $matchcase_elapsed ) / $ifelsif_elapsed;
   diag( sprintf "if/elsif took %.3fsec, this was %d%% faster at %.3fsec",
      $ifelsif_elapsed, $speedup * 100, $matchcase_elapsed );
}

done_testing;
