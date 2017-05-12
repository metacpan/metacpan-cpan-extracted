#!perl

use strict;
use warnings;

use Storable qw[ dclone ];
use Hash::Util qw[ lock_hash ];
use Params::Validate;

use Test::More tests => 4;

BEGIN {
    use_ok('Params::Validate::Aggregated', qw[ pv_disagg] );
}

my $func1_specs = { foo => 1, bar => 1 };
sub func1 {
    my %args = validate(@_, $func1_specs ) ;

    is_deeply( \%args, { foo => 'f', bar => 'b' }, 'func1' );
}

my $func2_specs = { goo => 1, loo => 1 };
sub func2 {

    my %args = validate(@_, $func2_specs );

    is_deeply( \%args, { goo => 'g', loo => 'l' }, 'func2' );

}

my $func_specs = { snack => 1, bar => 1 };
sub func {

    my ( $agg, $xtra ) = pv_disagg( params => \@_,
				       spec => {
						func  => $func_specs,
						func1 => $func1_specs,
						func2 => $func2_specs
					       }
				     );

    my %args = validate( @{[$agg->func]},  $func_specs );

    is_deeply ( \%args, { snack => 's', bar => 'b' }, 'func' );

    func1( $agg->func1 );
    func2( $agg->func2 );

}

func( foo => 'f', bar => 'b', snack => 's', goo => 'g', loo => 'l' );
