#! perl

use strict;
use warnings;

use Test2::Bundle::Extended;

use MooX::PDL2;


{
    package MyPolyNomial;

    use PDL::Lite;

    use Moo;
    extends 'MooX::PDL2';

    has x => (
        is       => 'rw',
        required => 1,
        trigger  => sub {
            $_[0]->_clear_PDL;
            $_[0]->_clear_cache
              if $_[1]->nelem != $_[0]->_cache->nelem;
        },
    );

    has coeffs => (
        is       => 'rw',
        required => 1,
        trigger  => sub { $_[0]->_clear_PDL },
    );


    has '+_PDL' => (
        init_args => undef,
        # required for Moo 2.003 (or below?)
        builder => \&_build__PDL
    );

    has _cache => (
        is      => 'lazy',
        builder => sub { $_[0]->x->ones },
        clearer => 1,
    );

    sub _build__PDL {

        my $self = shift;

        my $x     = $self->x;
        my $coeff = $self->coeffs;
        my $pdl   = $self->_cache;

        # this calculation is not robust at all
        $pdl .= $x->ones;
        $pdl *= $coeff->[0];

        for ( my $exp = 1 ; $exp < @$coeff + 1 ; ++$exp ) {
            $pdl += $coeff->[$exp] * $x**$exp;
        }
        $pdl;
    }
}

subtest "polynomial" => sub {

    my $m = MyPolyNomial->new( coeffs => [ 3, 4 ], x => PDL->sequence( 10 ) );

    is(
        $m->unpdl,
        [ 3, 7, 11, 15, 19, 23, 27, 31, 35, 39 ],
        "attrs set in constructor"
    );

    $m->coeffs( [ 1, 3, 20 ] );
    is( $m->unpdl, [ 1, 24, 87, 190, 333, 516, 739, 1002, 1305, 1648 ],
        "set coeffs" );

    $m->x( PDL->sequence( 4 ) );
    is( $m->unpdl, [ 1, 24, 87, 190 ], "set x" );

};

done_testing;
