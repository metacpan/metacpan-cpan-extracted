#!/usr/bin/env perl

use strict;
use warnings;
use PDL::LiteF;
use PDL::MatrixOps;
use PDL::Opt::QP;
use Test::More;
use Test::Exception;

my $mu   = pdl(q[ 0.0427 0.0015 0.0285 ])->transpose;    # [ n x 1 ]
my $mu_0 = 0.0427;
my $dmat = pdl q[ 0.0100 0.0018 0.0011 ;
                  0.0018 0.0109 0.0026 ;
                  0.0011 0.0026 0.0199 ];
my $dvec = zeros(3);

# mu' * x = mu_0
# 1'  * x = 1    (sum(x) = 1)
my $amat = $mu->glue( 0, ones( 1, 3 ) );
my $avec = pdl( $mu_0, 1 );

{
    # diag "n    = ", $mu->nelem;
    # diag "dmat = ", $dmat;
    # diag "dvec = ", $dvec;
    # diag "amat = ", $amat;
    # diag "avec = ", $avec;

    my $sol = qp( $dmat, $dvec, A_eq => $amat, a_eq => $avec );
    my $expected_sol = pdl [ 0.82745456, -0.090746123, 0.26329157 ];
    ok( all( approx $sol->{x}, $expected_sol, 1e-8 ), "Got expected solution" )
      or diag "Got $sol->{x}\nExpected: $expected_sol";
}

{
    my $bmat = identity(3);
    my $bvec = zeros(3);

    # diag "n    = ", $mu->nelem;
    # diag "dmat = ", $dmat;
    # diag "dvec = ", $dvec;
    # diag "amat'= ", $amat->transpose;
    # diag "avec = ", $avec;
    # diag "bmat'= ", $bmat->transpose;
    # diag "bvec = ", $bvec;

    my $sol = qp(
        $dmat, $dvec,
        A_eq  => $amat,
        a_eq  => $avec,
        A_neq => $bmat,
        a_neq => $bvec
    );
    my $expected_sol = pdl [ 1, 0, 0 ];
    ok( all( approx $sol->{x}, $expected_sol, 1e-8 ), "Got expected solution" )
      or diag "Got $sol->{x}\nExpected: $expected_sol";
}

{
    my $bmat = identity(3);
    my $bvec = zeros(3);

    $dmat = $dmat->glue( 2, $dmat );
    $dvec = $dvec->glue( 1, $dvec );
    $amat = $amat->glue( 2, $amat );
    $avec = $avec->glue( 1, $avec );
    $bmat = $bmat->glue( 2, $bmat );
    $bvec = $bvec->glue( 1, $bvec );

    # diag "n    = ", $mu->nelem;
    # diag "dmat = ", $dmat;
    # diag "dvec = ", $dvec;
    # diag "amat'= ", $amat->transpose;
    # diag "avec = ", $avec;
    # diag "bmat'= ", $bmat->transpose;
    # diag "bvec = ", $bvec;

    my $sol = qp(
        $dmat, $dvec,
        A_eq  => $amat,
        a_eq  => $avec,
        A_neq => $bmat,
        a_neq => $bvec
    );
    my $expected_sol = pdl [ 1, 0, 0 ], [ 1, 0, 0 ];
    ok( all( approx $sol->{x}, $expected_sol, 1e-8 ), "Got expected solution" )
      or diag "Got $sol->{x}\nExpected: $expected_sol";
}

done_testing;
