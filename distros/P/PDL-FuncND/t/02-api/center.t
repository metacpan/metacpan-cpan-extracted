#!perl

use PDL;
use Test::More;
use Test::Trap;
use PDL::Transform;

use strict;
use warnings;

use PDL::FuncND;

my $N = 99;

my $auto_center = ( pdl( [ $N, $N ] ) - 1 ) / 2;

my @offset = ( 2.2, 9.3 );

my $t = t_linear( { scale => pdl( [ 1, 3 ] ), offset => pdl( [ 12, 8 ] ) } );

my %specs = (
    grid => {
        self => 'PDL',
        opts => {},
        args => [ double, $N, $N ],
    },

    vector => {
        self => pdl( [ [ 1, 1 ] ] ),
        opts => { vectors => 1 },
        args => [],
    } );

sub _ok {

    my ( $got, $exp, $test ) = @_;

    $Test::Builder::Level = $Test::Builder::Level + 1;

    ok( all( $got == $exp ), $test )
      or diag( "    got: $got\n    exp: $exp" );
}

while ( my ( $label, $spec ) = each %specs ) {

    subtest "undefined center: $label" => sub {

        my %got = trap {
            PDL::FuncND::_handle_options(
                $spec->{self},
                { %{ $spec->{opts} } },
                @{ $spec->{args} } );
        };

        $trap->return_ok( 0, "return" );
        _ok( $got{center}, pdl( 0, 0 ), "value => piddle(0, 0)" );
    };

    subtest "auto center: $label" => sub {

        my %got = trap {
            PDL::FuncND::_handle_options(
                $spec->{self},
                { %{ $spec->{opts} }, center => 'auto' },
                @{ $spec->{args} } );
        };

        if ( $label eq 'vector' ) {

            $trap->die_like( qr/cannot use center = 'auto'/, "return" );

        }
        else {

            $trap->return_ok( 0, "return" );
            _ok( $got{center}, $auto_center, "value" );
        }

    };

    subtest "center piddle: $label" => sub {

        my %got = trap {
            PDL::FuncND::_handle_options(
                $spec->{self},
                { %{ $spec->{opts} }, center => pdl( 2, 3 ) },
                @{ $spec->{args} } );
        };

        $trap->did_return;
        _ok( $got{center}, pdl( 2, 3 ), "value" );
    };

    subtest "center arrayref: $label" => sub {

        my %got = trap {
            PDL::FuncND::_handle_options(
                $spec->{self},
                { %{ $spec->{opts} }, center => [ 2, 3 ] },
                @{ $spec->{args} } );
        };

        $trap->did_return;
        _ok( $got{center}, pdl( 2, 3 ), "value" );
    };

    subtest "center offset: $label" => sub {

        my %got = trap {
            PDL::FuncND::_handle_options(
                $spec->{self},
                { %{ $spec->{opts} }, center => [ offset => \@offset ] },
                @{ $spec->{args} } );
        };

        if ( $label eq 'vector' ) {

            $trap->die_like( qr/cannot use center = \[ offset/, "return" );

        }

        else {

            my $exp = $auto_center + pdl( \@offset );

            $trap->did_return;
            _ok( $got{center}, $exp, "value" );

        }

    };

    subtest "center offset, transformed: $label" => sub {

        my %got = trap {

            PDL::FuncND::_handle_options(
                $spec->{self},
                {
                    %{ $spec->{opts} },
                    center    => [ offset => \@offset ],
                    transform => $t
                },
                @{ $spec->{args} } );
        };

        if ( $label eq 'vector' ) {

            $trap->did_die;

        }

        else {

            my $exp = $auto_center->apply( $t ) + pdl( \@offset );

            $trap->did_return;
            _ok( $got{center}, $exp, "value" );

        }

    };

}


done_testing;
