#!perl

use strict;
use warnings;

use Test::More tests => 5;
use Storable qw[ dclone ];

use Hash::Util qw[ lock_hash ];
BEGIN {
  use_ok('Params::Validate::Aggregated', qw[ pv_disagg] );
}

my %def_with = (

	    spec1 => { spec => { foo => 1,
				 bar => 1,
			       },
		     },

	    spec2 => { spec => { foo => 1,
				 goo => 1,
			       },
		     },

	    spec3 => { spec => { bar => 1,
				 noo => 1,
			       },
		     },
	   );

lock_hash( %def_with );

my %def_exp = ( spec1 => { foo => 3, bar => 4 },
		spec2 => { foo => 3, goo => 2 },
		spec3 => { bar => 4 },
	      );

lock_hash( %def_exp );

my @def_params = ( foo => 3, bar => 4, goo => 2 );

{
    my ($args, $xtra ) = pv_disagg( params => \@def_params,
				       with => \%def_with,
				     );

    is_deeply( $args, \%def_exp, 'simple with' );
}

{
    my %with = %{ dclone( \%def_with ) };

    $with{spec1}{normalize_keys} = sub { uc $_[0] };
    my $spec = $with{spec1}{spec};
    $spec->{ uc $_} = delete $spec->{ $_ } for keys %$spec;

    my ($args, $xtra ) = pv_disagg( params => \@def_params,
				       with => \%with,
				     );

    is_deeply( $args, \%def_exp, 'block spec1: normalize_keys inputs: args' );
    is_deeply( $xtra, { }, 'block spec1: normalize_keys inputs: xtra' );
}

{
    my %with = %{ dclone( \%def_with ) };

    $with{spec1}{allow_extra} = 1;

    my %exp = %{ dclone( \%def_exp  )};

    $exp{spec1} = { @def_params };

    my ($args, $xtra ) = pv_disagg( params => \@def_params,
				       with => \%with,
				     );

    is_deeply( $args, \%exp, 'block spec1: extra params' );
}

