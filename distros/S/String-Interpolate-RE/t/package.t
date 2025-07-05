#! perl

use Test2::V0;

use String::Interpolate::RE;

my $interp;
ok( lives { $interp = String::Interpolate::RE::strinterp( '$a', { a => 1 } ) },
    "use package qualified function name" )
  or bail_out( "error accessing function via pacakge: $@" );

is( $interp, '1', "value" );

done_testing;
