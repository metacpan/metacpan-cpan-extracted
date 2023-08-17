#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use Syntax::Operator::ExistsOr;
BEGIN { plan skip_all => "No PL_infix_plugin" unless XS::Parse::Infix::HAVE_PL_INFIX_PLUGIN; }

my %counts;

package KeySv {
   sub TIESCALAR { return bless [], shift }

   sub FETCH { $counts{FETCH}++; return "KEY" }
}

my %hash = ( KEY => "VALUE" );
tie my $keysv, "KeySv";

# magic on keysv
{
   undef %counts;

   $hash{ $keysv } existsor 1;
   is( $counts{FETCH}, 1, 'existsor invoked FETCH magic on key exactly once' );
}

package TiedHv {
   sub TIEHASH { return bless [], shift }

   sub EXISTS { $counts{EXISTS}++; return 1 }
   sub FETCH  { $counts{FETCH}++; return "VALUE" }
}

tie %hash, "TiedHv";

# magic on HV
{
   undef %counts;

   $hash{THEKEY} existsor 1;

   is( \%counts, { EXISTS => 1, FETCH => 1 }, 'existsor invoked some magic??' );
}

done_testing;
