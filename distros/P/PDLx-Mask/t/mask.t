#!perl

use strict;
use warnings;

use Test::More;
use Test::Deep;

use Test::PDL qw[ is_pdl ];
use PDL::Lite;

use Safe::Isa;
use PDLx::Mask;

use Test::Fatal;
use Scalar::Util qw[ refaddr ];

require 't/fix_devel_cover.pl';

subtest "constructor" => sub {

    like( exception { PDLx::Mask->new; }, qr/missing required/i, 'no mask' );

    like(
        exception { PDLx::Mask->new( base => 'foo' ) },
        qr/coercion (.*) failed/ix,
        'mask not coercible'
    );

    is( exception { PDLx::Mask->new( { base => 0 } ) }, undef, 'hashref' );


    subtest "scalar" => sub {
        my $mask;

        is( exception { $mask = PDLx::Mask->new( base => 3 ) },
            undef, 'construct' );

        ok( $mask->base->$_isa( 'PDL' ), 'base is PDL' );

        is( $mask->base->type, PDL::byte, 'base is byte PDL', );
    };

    subtest "arrayref" => sub {
        my $mask;

        is( exception { $mask = PDLx::Mask->new( base => [ 1, 1, 1 ] ) },
            undef, 'construct' );

        ok( $mask->base->$_isa( 'PDL' ), 'base is PDL' );

        is( $mask->base->type, PDL::byte, 'base is byte PDL', );

        cmp_deeply( $mask->mask->unpdl, [ 1, 1, 1 ], 'values ok' );
    };

};

subtest "forbid mutatation" => sub {

    my $mask = PDLx::Mask->new( [ 1, 1, 1 ] );

    require overload;

    like( exception { eval "\$mask $_ 0"; die $@ if $@ },
        qr/cannot mutate/, $_ ) foreach grep { $_ ne '.=' }
      map { split( ' ', $_ ) } $overload::ops{'assign'};

    like( exception { eval "\$mask $_"; die $@ if $@ }, qr/cannot mutate/, $_ )
      foreach map { split( ' ', $_ ) } $overload::ops{'mutators'};

    like( exception { $mask->inplace }, qr/cannot mutate/, 'inplace' );
    like(
        exception { $mask->set_inplace( 1 ) },
        qr/cannot mutate/,
        'set_inplace(1)'
    );
    is( exception { $mask->set_inplace( 0 ) }, undef, 'set_inplace(0)' );


};


subtest "post-constructor mask assignment" => sub {

    my $mask;
    is(
        exception {
            $mask = PDLx::Mask->new( [ 1, 0, 1 ] )
        },
        undef,
        'construct'
    );

    $mask->mask( [ 1, 1, 1 ] );
    cmp_deeply( $mask->unpdl, [ 1, 1, 1 ], 'mask values ok' );
    is( $mask->nvalid, 3, 'number of valid values' );
};

subtest "subscribe" => sub {

    like(
        exception { PDLx::Mask->new( 1 )->subscribe() },
        qr/one or more of/,
        "no apply_mask or data_mask",
    );

    like(
        exception { PDLx::Mask->new( 1 )->subscribe( apply_mask => 0 ) },
        qr/apply_mask.*invalid type/,
        "illegal apply_mask",
    );

    like(
        exception { PDLx::Mask->new( 1 ) ->subscribe( data_mask => 0 )
        },
        qr/data_mask.*invalid type/,
        "illegal data_mask",
    );

    like(
        exception {
            PDLx::Mask->new( 1 )->subscribe( apply_mask => sub { }, token => 0 )
        },
        qr/invalid token/,
        "illegal token",
    );

    subtest "mask reflects subscription" => sub   {

	my $mask = PDLx::Mask->new( [ 1, 0, 1 ] );
	my $token = $mask->subscribe( data_mask => sub { [ 0, 0, 0 ] } );
	cmp_deeply( $mask->unpdl, [ 0, 0, 0 ], "mask value" );

	$mask->unsubscribe( $token );

	cmp_deeply( $mask->unpdl, $mask->base->unpdl, "effective mask == base mask upon unsubscription" );

    };


};

subtest 'overload assignment ops/methods' => sub {

        {
	    # copying returns a normal piddle
	    my $mask = PDLx::Mask->new( [ 1, 0, 1 ] );
	    $mask->subscribe( data_mask => sub { [ 1, 0, 0 ] },
			    );
	    my $copy = $mask->copy;

	    ok( $copy->isa( 'PDL' ) && ! $copy->isa( 'PDLx::Mask' ), '$mask->copy => ordinary PDL' );

	    cmp_deeply( $copy->unpdl, [ 1, 0, 0 ], "copy returns effective mask" );

	    # operating on a mask results in a normal piddle
	    my $pdl = $mask + 1;

	    ok( $pdl->isa( 'PDL' ) && ! $pdl->isa( 'PDLx::Mask' ), '$mask + 1 => ordinary PDL' );

	    cmp_deeply( $pdl->unpdl, [ 2, 1, 1 ], '$mask + 1 => operates on effective mask' );

        }

        {
            is( PDLx::Mask->new( [ 1, 0, 1 ] )->is_inplace(),
                0, 'set_inplace', );
        }

    subtest 'no data mask' => sub {

        subtest '.=' => sub {

            my $mask = PDLx::Mask->new( [ 1, 0, 1 ] );

            is( $mask->nvalid, 2, "effective number of elements" );

            my $pdata;
            $mask->subscribe( apply_mask => sub { $pdata = 1 } );

            is( exception { $mask .= pdl( 0, 1, 0 ); }, undef, 'assign' );

            cmp_deeply( $mask->base->unpdl, [ 0, 1, 0 ], 'base values ok' );
            cmp_deeply( $mask->mask->unpdl, [ 0, 1, 0 ], 'mask values ok' );

            is( $mask->nvalid, 1, "effective number of elements" );

            ok( defined $pdata, "subscribed" );

        };

        subtest '|=' => sub {

            my $mask = PDLx::Mask->new( [ 1, 0, 1 ] );
            is( $mask->nvalid, 2, "effective number of elements" );

            my $pdata;
            $mask->subscribe( apply_mask => sub { $pdata = 1 } );

            is( exception { $mask |= pdl( 0, 1, 0 ) }, undef, 'assign' );

            cmp_deeply( $mask->base->unpdl, [ 1, 1, 1 ], 'base values ok' );
            cmp_deeply( $mask->mask->unpdl, [ 1, 1, 1 ], 'mask values ok' );

            is( $mask->nvalid, 3, "effective number of elements" );

            ok( defined $pdata, "subscribed" );

        };

        subtest '&=' => sub {

            my $mask = PDLx::Mask->new( [ 1, 0, 1 ] );
            is( $mask->nvalid, 2, "effective number of elements" );

            my $pdata;
            $mask->subscribe( apply_mask => sub { $pdata = 1 } );

            is( exception { $mask &= pdl( 0, 1, 1 ) }, undef, 'assign' );

            cmp_deeply( $mask->base->unpdl, [ 0, 0, 1 ], 'base values ok' );
            cmp_deeply( $mask->mask->unpdl, [ 0, 0, 1 ], 'mask values ok' );

            is( $mask->nvalid, 1, "effective number of elements" );

            ok( defined $pdata, "subscribed" );
        };

        subtest '^=' => sub {

            my $mask = PDLx::Mask->new( [ 1, 0, 1 ] );
            is( $mask->nvalid, 2, "effective number of elements" );

            my $pdata;
            $mask->subscribe( apply_mask => sub { $pdata = 1 } );

            is( exception { $mask ^= pdl( 0, 1, 0 ) }, undef, 'assign' );

            cmp_deeply( $mask->base->unpdl, [ 1, 1, 1 ], 'base values ok' );
            cmp_deeply( $mask->mask->unpdl, [ 1, 1, 1 ], 'mask values ok' );

            is( $mask->nvalid, 3, "effective number of elements" );

            ok( defined $pdata, "subscribed" );

        };

        subtest 'set' => sub {

            my $mask = PDLx::Mask->new( [ 1, 0, 1 ] );
            is( $mask->nvalid, 2, "effective number of elements" );

            my $pdata;
            $mask->subscribe( apply_mask => sub { $pdata = 1 } );

            is( exception { $mask->set( 1, 1 ) }, undef, 'assign' );

            cmp_deeply( $mask->base->unpdl, [ 1, 1, 1 ], 'base values ok' );
            cmp_deeply( $mask->mask->unpdl, [ 1, 1, 1 ], 'mask values ok' );

            is( $mask->nvalid, 3, "effective number of elements" );

            ok( defined $pdata, "subscribed" );

        };


    };


    subtest 'data mask' => sub {

        subtest '|=' => sub {

            my $mask = PDLx::Mask->new( [ 1, 0, 1 ] );
            is( $mask->nvalid, 2, "effective number of elements" );

            my $pdata;
            $mask->subscribe(
                apply_mask => sub { $pdata = 1 },
                data_mask => sub { [ 0, 0, 1 ] },
            );

            is( exception { $mask |= pdl( 0, 1, 0 ) }, undef, 'assign' );

            cmp_deeply( $mask->base->unpdl, [ 1, 1, 1 ], 'base values ok' );
            cmp_deeply( $mask->mask->unpdl, [ 0, 0, 1 ], 'mask values ok' );

            is( $mask->nvalid, 1, "effective number of elements" );

        };

        subtest '&=' => sub {

            my $mask = PDLx::Mask->new( [ 1, 0, 1 ] );
            is( $mask->nvalid, 2, "effective number of elements" );

            my $pdata;
            $mask->subscribe(
                apply_mask => sub { $pdata = 1 },
                data_mask => sub { [ 0, 0, 1 ] },
            );

            is( exception { $mask &= pdl( 0, 1, 1 ) }, undef, 'assign' );

            cmp_deeply( $mask->base->unpdl, [ 0, 0, 1 ], 'base values ok' );
            cmp_deeply( $mask->mask->unpdl, [ 0, 0, 1 ], 'mask values ok' );

            is( $mask->nvalid, 1, "effective number of elements" );

        };

        subtest '^=' => sub {

            my $mask = PDLx::Mask->new( [ 1, 0, 1 ] );
            is( $mask->nvalid, 2, "effective number of elements" );

            my $pdata;
            $mask->subscribe(
                apply_mask => sub { $pdata = 1 },
                data_mask => sub { [ 0, 0, 1 ] },
            );

            is( exception { $mask ^= pdl( 0, 1, 0 ) }, undef, 'assign' );

            cmp_deeply( $mask->base->unpdl, [ 1, 1, 1 ], 'base values ok' );
            cmp_deeply( $mask->mask->unpdl, [ 0, 0, 1 ], 'mask values ok' );

            is( $mask->nvalid, 1, "effective number of elements" );
        };

    };

};

done_testing;
