#!perl

use strict;
use warnings;

use Test2::V0 '!float';
use Test2::Tools::PDL;
use Test::Lib;
use PDL::Lite;

use Safe::Isa;
use PDLx::Mask;

require fix_devel_cover;

subtest "constructor" => sub {

    like( dies { PDLx::Mask->new; }, qr/missing required/i, 'no mask' );

    like(
        dies { PDLx::Mask->new( base => 'foo' ) },
        qr/coercion (.*) failed/ix,
        'mask not coercible'
    );

    ok( lives { PDLx::Mask->new( { base => 0 } ) }, 'hashref' ) or note $@;


    subtest "scalar" => sub {
        my $mask;

        ok( lives { $mask = PDLx::Mask->new( base => 3 ) }, 'construct' )
          or note $@;

        ok( $mask->base->$_isa( 'PDL' ), 'base is PDL' );

        is( $mask->base->type, PDL::byte, 'base is byte PDL', );
    };

    subtest "arrayref" => sub {
        my $mask;

        ok( lives { $mask = PDLx::Mask->new( base => [ 1, 1, 1 ] ) },
            'construct' )
          or note $@;

        ok( $mask->base->$_isa( 'PDL' ), 'base is PDL' );

        is( $mask->base->type, PDL::byte, 'base is byte PDL', );

        pdl_is( $mask->mask, pdl( 1, 1, 1 ), 'values ok' );
    };

};

subtest "forbid mutatation" => sub {

    my $mask = PDLx::Mask->new( [ 1, 1, 1 ] );

    require overload;

    like( dies { eval "\$mask $_ 0"; die $@ if $@ }, qr/cannot mutate/, $_ )
      foreach grep { $_ ne '.=' }
      map { split( ' ', $_ ) } $overload::ops{'assign'};

    like( dies { eval "\$mask $_"; die $@ if $@ }, qr/cannot mutate/, $_ )
      foreach map { split( ' ', $_ ) } $overload::ops{'mutators'};

    like( dies { $mask->inplace }, qr/cannot mutate/, 'inplace' );
    like(
        dies { $mask->set_inplace( 1 ) },
        qr/cannot mutate/,
        'set_inplace(1)'
    );
    ok( lives { $mask->set_inplace( 0 ) }, 'set_inplace(0)' ) or note $@;


};


subtest "post-constructor mask assignment" => sub {

    my $mask;
    ok( lives { $mask = PDLx::Mask->new( [ 1, 0, 1 ] ) }, 'construct' )
      or note $@;

    $mask->mask( [ 1, 1, 1 ] );
    pdl_is( $mask->mask, pdl( 1, 1, 1 ), 'mask values ok' );
    is( $mask->nvalid, 3, 'number of valid values' );
};

subtest "subscribe" => sub {

    like(
        dies { PDLx::Mask->new( 1 )->subscribe() },
        qr/one or more of/,
        "no apply_mask or data_mask",
    );

    like(
        dies { PDLx::Mask->new( 1 )->subscribe( apply_mask => 0 ) },
        qr/apply_mask.*invalid type/,
        "illegal apply_mask",
    );

    like(
        dies {
            PDLx::Mask->new( 1 )->subscribe( data_mask => 0 )
        },
        qr/data_mask.*invalid type/,
        "illegal data_mask",
    );

    like(
        dies {
            PDLx::Mask->new( 1 )->subscribe( apply_mask => sub { }, token => 0 )
        },
        qr/invalid token/,
        "illegal token",
    );

    subtest "mask reflects subscription" => sub {

        my $mask  = PDLx::Mask->new( [ 1, 0, 1 ] );
        my $token = $mask->subscribe( data_mask => sub { [ 0, 0, 0 ] } );
        pdl_is( $mask->mask, pdl( 0, 0, 0 ), "mask value" );

        $mask->unsubscribe( $token );

        pdl_is( $mask->mask, $mask->base,
            "effective mask == base mask upon unsubscription" );

    };


};

subtest 'overload assignment ops/methods' => sub {

    {
        # copying returns a normal piddle
        my $mask = PDLx::Mask->new( [ 1, 0, 1 ] );
        $mask->subscribe( data_mask => sub { [ 1, 0, 0 ] }, );
        my $copy = $mask->copy;

        ok( $copy->isa( 'PDL' ) && !$copy->isa( 'PDLx::Mask' ),
            '$mask->copy => ordinary PDL' );

        pdl_is( $copy, pdl( 1, 0, 0 ), "copy returns effective mask" );

        # operating on a mask results in a normal piddle
        my $pdl = $mask + 1;

        ok( $pdl->isa( 'PDL' ) && !$pdl->isa( 'PDLx::Mask' ),
            '$mask + 1 => ordinary PDL' );

        pdl_is(
            $pdl,
            pdl( 2, 1, 1 ),
            '$mask + 1 => operates on effective mask'
        );

    }

    {
        is( PDLx::Mask->new( [ 1, 0, 1 ] )->is_inplace(), 0, 'set_inplace', );
    }

    subtest 'no data mask' => sub {

        subtest '.=' => sub {

            my $mask = PDLx::Mask->new( [ 1, 0, 1 ] );

            is( $mask->nvalid, 2, "effective number of elements" );

            my $pdata;
            $mask->subscribe( apply_mask => sub { $pdata = 1 } );

            ok( lives { $mask .= pdl( 0, 1, 0 ); }, 'assign' ) or note $@;

            pdl_is( $mask->base, pdl( 0, 1, 0 ), 'base values ok' );
            pdl_is( $mask->mask, pdl( 0, 1, 0 ), 'mask values ok' );

            is( $mask->nvalid, 1, "effective number of elements" );

            ok( defined $pdata, "subscribed" );

        };

        subtest '|=' => sub {

            my $mask = PDLx::Mask->new( [ 1, 0, 1 ] );
            is( $mask->nvalid, 2, "effective number of elements" );

            my $pdata;
            $mask->subscribe( apply_mask => sub { $pdata = 1 } );

            ok( lives { $mask |= pdl( 0, 1, 0 ) }, 'assign' ) or note $@;

            pdl_is( $mask->base, pdl( 1, 1, 1 ), 'base values ok' );
            pdl_is( $mask->mask, pdl( 1, 1, 1 ), 'mask values ok' );

            is( $mask->nvalid, 3, "effective number of elements" );

            ok( defined $pdata, "subscribed" );

        };

        subtest '&=' => sub {

            my $mask = PDLx::Mask->new( [ 1, 0, 1 ] );
            is( $mask->nvalid, 2, "effective number of elements" );

            my $pdata;
            $mask->subscribe( apply_mask => sub { $pdata = 1 } );

            ok( lives { $mask &= pdl( 0, 1, 1 ) }, 'assign' ) or note $@;

            pdl_is( $mask->base, pdl( 0, 0, 1 ), 'base values ok' );
            pdl_is( $mask->mask, pdl( 0, 0, 1 ), 'mask values ok' );

            is( $mask->nvalid, 1, "effective number of elements" );

            ok( defined $pdata, "subscribed" );
        };

        subtest '^=' => sub {

            my $mask = PDLx::Mask->new( [ 1, 0, 1 ] );
            is( $mask->nvalid, 2, "effective number of elements" );

            my $pdata;
            $mask->subscribe( apply_mask => sub { $pdata = 1 } );

            ok( lives { $mask ^= pdl( 0, 1, 0 ) }, 'assign' ) or note $@;

            pdl_is( $mask->base, pdl( 1, 1, 1 ), 'base values ok' );
            pdl_is( $mask->mask, pdl( 1, 1, 1 ), 'mask values ok' );

            is( $mask->nvalid, 3, "effective number of elements" );

            ok( defined $pdata, "subscribed" );

        };

        subtest 'set' => sub {

            my $mask = PDLx::Mask->new( [ 1, 0, 1 ] );
            is( $mask->nvalid, 2, "effective number of elements" );

            my $pdata;
            $mask->subscribe( apply_mask => sub { $pdata = 1 } );

            ok( lives { $mask->set( 1, 1 ) }, 'assign' ) or note $@;

            pdl_is( $mask->base, pdl( 1, 1, 1 ), 'base values ok' );
            pdl_is( $mask->mask, pdl( 1, 1, 1 ), 'mask values ok' );

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
                data_mask  => sub { [ 0, 0, 1 ] },
            );

            ok( lives { $mask |= pdl( 0, 1, 0 ) }, 'assign' ) or note $@;

            pdl_is( $mask->base, pdl( 1, 1, 1 ), 'base values ok' );
            pdl_is( $mask->mask, pdl( 0, 0, 1 ), 'mask values ok' );

            is( $mask->nvalid, 1, "effective number of elements" );

        };

        subtest '&=' => sub {

            my $mask = PDLx::Mask->new( [ 1, 0, 1 ] );
            is( $mask->nvalid, 2, "effective number of elements" );

            my $pdata;
            $mask->subscribe(
                apply_mask => sub { $pdata = 1 },
                data_mask  => sub { [ 0, 0, 1 ] },
            );

            ok( lives { $mask &= pdl( 0, 1, 1 ) }, 'assign' ) or note $@;

            pdl_is( $mask->base, pdl( 0, 0, 1 ), 'base values ok' );
            pdl_is( $mask->mask, pdl( 0, 0, 1 ), 'mask values ok' );

            is( $mask->nvalid, 1, "effective number of elements" );

        };

        subtest '^=' => sub {

            my $mask = PDLx::Mask->new( [ 1, 0, 1 ] );
            is( $mask->nvalid, 2, "effective number of elements" );

            my $pdata;
            $mask->subscribe(
                apply_mask => sub { $pdata = 1 },
                data_mask  => sub { [ 0, 0, 1 ] },
            );

            ok( lives { $mask ^= pdl( 0, 1, 0 ) }, 'assign' ) or note $@;

            pdl_is( $mask->base, pdl( 1, 1, 1 ), 'base values ok' );
            pdl_is( $mask->mask, pdl( 0, 0, 1 ), 'mask values ok' );

            is( $mask->nvalid, 1, "effective number of elements" );
        };

    };

};

done_testing;
