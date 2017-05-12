#! perl

# check that a single vector is handled correctly

use Test::More;
use Test::Trap;

use PDL;
use PDL::FuncND;


for my $pars ( [ '0D', 0 ], [ '1D', 1 ], [ '2D', 2, ] ) {

    my ( $label, $ndims ) = @$pars;

    my $x = $ndims > 0 ? ones( $ndims )     : pdl( 1 );
    my $S = $ndims > 0 ? identity( $ndims ) : pdl( 1 );


    subtest "mahalanobis: $label" => sub {

        my $x = $x->copy;
        my $S = $S->copy;

        my $d2 = trap { mahalanobis( $x, $S, { squared => 1 } ); };

        $trap->did_return;
        is( $d2->ndims, 1, 'extent correct' )
          or return;

        is( ( $d2->dims )[0], 1, 'dim[0] correct' )
          or return;

        is( $d2->sclr, $ndims || 1, 'value correct' );

    };

    for my $func (
        [ cauchyND  => \&PDL::FuncND::cauchyND ],
        [ gaussND   => \&PDL::FuncND::gaussND ],
        [ lorentzND => \&PDL::FuncND::lorentzND ],
        [ moffatND  => \&PDL::FuncND::moffatND, { alpha => 1, beta => 2 } ],
      )
    {
        my ( $name, $sub, $pars ) = @$func;

	$pars = {} unless defined $pars;

        subtest "$name: $label" => sub {

            my $x = $x->copy;

            my $g = trap { $sub->( $x, { %$pars, vectors => 1 } ); };

            $trap->did_return;
            is( $g->ndims, 1, 'extent correct' )
              or return;

            is( ( $g->dims )[0], 1, 'dim[0] correct' )
              or return;


        };

    }


}

done_testing;
