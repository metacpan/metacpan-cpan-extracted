#!perl

use strict;
use warnings;

use Storable qw[ dclone ];
use Hash::Util qw[ lock_hash ];

use Test::More tests => 14;

BEGIN {
  use_ok('Params::Validate::Aggregated', qw[ pv_disagg] );
}

my %specs = (

	     spec1 => { foo => 1,
			bar => 1,
		      },

	     spec2 => { foo => 1,
			goo => 1,
		      },

	     spec3 => { bar => 1,
			noo => 1,
		      },
);

lock_hash( %specs );

my %def_exp = ( spec1 => { foo => 3, bar => 4 },
		spec2 => { foo => 3, goo => 2 },
		spec3 => { bar => 4 },
	      );

lock_hash( %def_exp );

my @def_params = ( foo => 3, bar => 4, goo => 2 );

{
    my @params = ( @def_params, xtra => 1 );

    my ($args, $xtra ) = pv_disagg( params => \@params,
				       spec => \%specs,
				     );

    is_deeply( $args, \%def_exp, 'simple spec: args' );
    is_deeply( $xtra, { xtra => 1 }, 'simple spec: xtra' );

    $params[1] = 99;
    $params[3] = 100;
    $params[5] = 101;
    is( $args->{spec1}{foo},  99, 'spec1: foo' );
    is( $args->{spec1}{bar}, 100, 'spec1: bar' );
    is( $args->{spec2}{foo},  99, 'spec2: foo' );
    is( $args->{spec2}{goo}, 101, 'spec2: goo' );
    is( $args->{spec3}{bar}, 100, 'spec3: bar' );

    $params[-1] = 99;
    is( $xtra->{xtra}, 99, 'simple spec: xtra' );
}

{
    my @params = ( @def_params, xtra => 1 );

    my ($args, $xtra ) = pv_disagg( params => \@params,
				       spec => \%specs,
				       allow_extra => 1,
				     );

    my %exp = map { $_ => { @params } } keys %specs;

    is_deeply( $args, \%exp, 'allow_extra = true: args' );
    is_deeply( $xtra, { }, 'allow_extra = true: xtra' );

    $params[-1] = 20;

    is( $args->{$_}{xtra}, 20, "$_: xtra" )
      for qw[ spec1 spec2 spec3];

}
