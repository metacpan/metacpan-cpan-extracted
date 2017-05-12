#!/usr/bin/env perl

use strict;
use warnings;
use PDL::LiteF;
use PDL::MatrixOps;
use PDL::Opt::QP;
use Test::More;

my $mu   = pdl(q[ 0.0427 0.0015 0.0285 ])->transpose;    # [ n x 1 ]
my $mu_0 = 0.0427;
my $dmat = pdl q[ 0.0100 0.0018 0.0011 ;
                  0.0018 0.0109 0.0026 ;
                  0.0011 0.0026 0.0199 ];
my $dvec = zeros(3);
my $amat = $mu->glue( 0, ones( 1, 3 ) )->copy;
my $bvec = pdl($mu_0)->glue( 1, ones(1) )->flat;
my $meq  = pdl(2);

{
    # diag "n    = ", $mu->nelem;
    # diag "dmat = ", $dmat;
    # diag "dvec = ", $dvec;
    # diag "amat'= ", $amat->transpose;
    # diag "bvec = ", $bvec;

    my $sol = qp_orig( $dmat, $dvec, $amat, $bvec, $meq );
    my $expected_sol = pdl [ 0.82745456, -0.090746123, 0.26329157 ];
    ok( all( approx $sol->{x}, $expected_sol, 1e-8), "Got expected solution" )
      or diag "Got $sol->{x}\nExpected: $expected_sol";
}

{
    $amat = $amat->glue( 0, identity(3) );
    $bvec = $bvec->glue( 0, zeros(3) )->flat;

    # diag "n    = ", $mu->nelem;
    # diag "dmat = ", $dmat;
    # diag "dvec = ", $dvec;
    # diag "amat'= ", $amat->transpose;
    # diag "bvec = ", $bvec;

    my $sol = qp_orig( $dmat, $dvec, $amat, $bvec, $meq );
    my $expected_sol = pdl [ 1, 0, 0 ];
    ok( all( approx $sol->{x}, $expected_sol, 1e-8 ), "Got expected solution" )
      or diag "Got $sol->{x}\nExpected: $expected_sol";
}

done_testing;
