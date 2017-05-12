#!perl

use strict;
use warnings;

use Storable qw[ dclone ];
use Hash::Util qw[ lock_hash ];

use Test::More tests => 13;

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
    my ($args, $xtra ) = pv_disagg( params => \@def_params,
				       spec => \%specs,
				     );

    is_deeply( $args, \%def_exp, 'simple spec: args' );
    is_deeply( $xtra, { }, 'simple spec: xtra' );
}

{
    my @params = ( @def_params, xtra => 1 );
    my ($args, $xtra ) = pv_disagg( params => \@params,
				       spec => \%specs,
				     );

    is_deeply( $args, \%def_exp, 'extras, allow_extra = false: args' );
    is_deeply( $xtra, { xtra => 1 }, 'extras, allow_extra = false: xtra' );
}


{
    my ($args, $xtra ) = pv_disagg( params => \@def_params,
				       spec => \%specs,
				       allow_extra => 1,
				     );

    # everything is allowed, so everyone gets everything
    my %exp = @def_params;

    is_deeply( $args, { spec1 => \%exp,
			spec2 => \%exp,
			spec3 => \%exp,
		      },
	       'allow_extra = true: args' );
    is_deeply( $xtra, { }, 'allow_extra = true: xtra' );

}

{
    my @params = ( @def_params, xtra => 1 );
    my ($args, $xtra ) = pv_disagg( params => \@params,
				       spec => \%specs,
				       allow_extra => 1,
				     );

    # everything is allowed, so everyone gets everything
    my %exp = @params;

    is_deeply( $args, { spec1 => \%exp,
			spec2 => \%exp,
			spec3 => \%exp,
		      },
	       'extras, allow_extra = true : args' );
    is_deeply( $xtra, { }, 'extras, allow_extra = true: xtra' );
}


# test normalize_keys
{
    my @uparams = map { uc $_ } @def_params;

    my ($args, $xtra ) = pv_disagg( params => \@uparams,
				       spec => \%specs,
				       normalize_keys => sub { lc $_[0] },
				     );

    # upper case the results
    my %exp = %{ dclone( \%def_exp ) };
    for my $spec ( values %exp ) {
	my @keys = keys %$spec;
	$spec->{uc $_} = delete $spec->{$_} for @keys;
    }

    is_deeply( $args, \%exp, 'global normalize_keys; inputs: args' );
    is_deeply( $xtra, { }, 'global normalize_keys; inputs: xtra' );
}


{
    my ($args, $xtra ) = pv_disagg( params => \@def_params,
				       spec => \%specs,
				       normalize_keys => sub { uc $_[0] },
				     );

    is_deeply( $args, \%def_exp, 'global normalize_keys; both: args' );
    is_deeply( $xtra, { }, 'global normalize_keys; both: xtra' );
}
