#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;
BEGIN {
   eval { require List::Util; List::Util->VERSION(1.56) } or
      plan skip_all => "List::Util v1.56 is not available";
}

# This "test" never fails, but prints a benchmark comparison between these
# wrapper functions and the ones in Scalar::Util

use Time::HiRes qw( gettimeofday tv_interval );
sub measure(&)
{
   my ( $code ) = @_;
   my $start = [ gettimeofday ];
   $code->();
   return tv_interval $start;
}

my @nums = ( 1 .. 100 );

my $COUNT = 5_000;

my $SOZ_elapsed = 0;
my $LU_elapsed = 0;

# To reduce the influence of bursts of timing noise, interleave many small runs
# of each type.

foreach ( 1 .. 20 ) {
   my $overhead = measure {};

   $SOZ_elapsed += -$overhead + measure {
      use Syntax::Operator::Zip ();
      my @ret;
      ( @ret = Syntax::Operator::Zip::zip [1..5], ['a'..'e'] ) for 1 .. $COUNT;
   };
   $LU_elapsed += -$overhead + measure {
      use List::Util 1.56 ();
      my @ret;
      ( @ret = List::Util::zip [1..5], ['a'..'e'] ) for 1 .. $COUNT;
   };
}

pass( "Benchmarked" );

if( $SOZ_elapsed > $LU_elapsed ) {
   diag( sprintf "List::Util took %.3fsec, ** this was SLOWER at %.3fsec **",
      $LU_elapsed, $SOZ_elapsed );
}
else {
   my $speedup = ( $LU_elapsed - $SOZ_elapsed ) / $LU_elapsed;
   diag( sprintf "List::Util took %.3fsec, this was %d%% faster at %.3fsec",
      $LU_elapsed, $speedup * 100, $SOZ_elapsed );
}

done_testing;
