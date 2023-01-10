#!perl

use Test2::V0 '!float';
use Test2::Tools::PDL;
use Test::Lib;
use PDL::Lite;

use Safe::Isa;
use PDLx::Mask;
use PDLx::MaskedData;

require fix_devel_cover;

sub badat {
    my @vals = @_;
    my @bad  = grep $vals[$_] eq 'BAD', 0 .. $#vals;

    @vals[@bad] = 0;
    my $pdl = pdl( @vals );
    $pdl->setbadat( $_ ) for @bad;
    return $pdl;
}


subtest "constructor" => sub {

    like(
        dies { PDLx::MaskedData->new },
        qr/missing required/i,
        'no base, no mask'
    );

    like(
        dies { PDLx::MaskedData->new( mask => 0 ) },
        qr/missing required/i,
        'no base, mask'
    );

    like(
        dies { PDLx::MaskedData->new( base => 'foo', mask => 0 ) },
        qr/coercion (.*) failed/ix,
        'base not coercible'
    );

    like(
        dies { PDLx::MaskedData->new( base => 0, mask => 'foo' ) },
        qr/coercion (.*) failed/ix,
        'mask not coercible'
    );

    is( dies { PDLx::MaskedData->new( { base => 0 } ) }, undef, 'hashref' );

    subtest "base, no mask" => sub {

        subtest "no upstream" => sub {

            my $data;

            ok( lives { $data = PDLx::MaskedData->new( base => 0 ) },
                "constructor" )
              or note $@;

            ok( $data->mask->$_isa( 'PDLx::Mask' ), 'mask is PDLx::Mask' );

            pdl_is( $data->base,       pdl( 0 ), 'base values' );
            pdl_is( $data->mask->mask, pdl( 1 ), 'mask values' );

        };

        subtest "no upstream, upstream bad, no masked values" => sub {

            my $data;
            my $pdl = pdl( 0, 1 );
            $pdl->badflag( 1 );

            ok(
                lives {
                    $data
                      = PDLx::MaskedData->new( base => $pdl, data_mask => 1 )
                },
                "constructor",
            ) or note $@;

            ok( $data->mask->$_isa( 'PDLx::Mask' ), 'mask is PDLx::Mask' );

            pdl_is( $data->base,       pdl( 0, 1 ), 'base values' );
            pdl_is( $data->mask->mask, pdl( 1, 1 ), 'mask values' );

        };

        subtest "no upstream, upstream bad, masked values" => sub {

            my $data;

            my $pdl = badat( 'BAD', 1, 2 );

            ok(
                lives {
                    $data = PDLx::MaskedData->new(
                        base      => $pdl,
                        data_mask => 1,
                        mask      => [ 1, 1, 0 ],
                    )
                },
                "constructor",
            ) or note $@;

            ok( $data->mask->$_isa( 'PDLx::Mask' ), 'mask is PDLx::Mask' );

            pdl_is( $data->base,       badat( 'BAD', 1, 2 ), 'base values' );
            pdl_is( $data->_data_mask, pdl( [ 0, 1, 1 ] ), 'data mask values' );
            pdl_is( $data->mask->mask, pdl( [ 0, 1, 0 ] ), 'mask values' );
            pdl_is( $data->data, badat( 'BAD', 1, 'BAD' ), 'data values' );
            is( $data->nvalid, 1, 'number of valid values' );

        };

        subtest "no upstream, upstream value, no masked values" => sub {

            my $data;
            my $pdl = pdl( 1 );

            ok(
                lives {
                    $data = PDLx::MaskedData->new(
                        base       => $pdl,
                        data_mask  => 1,
                        mask_value => 0
                    )
                },
                "constructor",
            ) or note $@;

            ok( $data->mask->$_isa( 'PDLx::Mask' ), 'mask is PDLx::Mask' );

            pdl_is( $data->base,       pdl( 1 ), 'base values' );
            pdl_is( $data->mask->mask, pdl( 1 ), 'mask values' );
            is( $data->nvalid, 1, 'number of valid values' );
        };

        subtest "no upstream, upstream value, masked values" => sub {

            my $data;
            my $pdl = pdl( 0 );

            ok(
                lives {
                    $data = PDLx::MaskedData->new(
                        base       => $pdl,
                        data_mask  => 1,
                        mask_value => 0
                    )
                },
                "constructor",
            ) or note $@;

            ok( $data->mask->$_isa( 'PDLx::Mask' ), 'mask is PDLx::Mask' );

            pdl_is( $data->base,       pdl( 0 ), 'base values' );
            pdl_is( $data->mask->mask, pdl( 0 ), 'mask values' );
            is( $data->nvalid, 0, 'number of valid values' );
        };

    };


    subtest "scalar, scalar" => sub {
        my $data;

        ok( lives { $data = PDLx::MaskedData->new( base => 3, mask => 4 ) },
            'construct' )
          or note $@;

        ok( $data->base->$_isa( 'PDL' ),        'base is PDL' );
        ok( $data->mask->$_isa( 'PDLx::Mask' ), 'mask is PDLx::Mask' );

        pdl_is( $data->base,       pdl( 3 ), 'base values' );
        pdl_is( $data->mask->mask, pdl( 4 ), 'mask values' );
        is( $data->nvalid, 1, 'number of valid values' );

    };

    subtest "scalar, Mask" => sub {
        my $data;

        ok(
            lives {
                $data = PDLx::MaskedData->new(
                    base => 3,
                    mask => PDLx::Mask->new( 4 ) )
            },
            'construct'
        ) or note $@;

        ok( $data->base->$_isa( 'PDL' ),        'base is PDL' );
        ok( $data->mask->$_isa( 'PDLx::Mask' ), 'mask is PDLx::Mask' );

        pdl_is( $data->base,       pdl( 3 ), 'base values' );
        pdl_is( $data->mask->mask, pdl( 4 ), 'mask values' );
        is( $data->nvalid, 1, 'number of valid values' );

    };

    subtest "arrayref, arrayref" => sub {
        my $data;

        ok(
            lives {
                $data = PDLx::MaskedData->new(
                    base => [ 2, 3, 4 ],
                    mask => [ 1, 1, 1 ] )
            },
            'construct'
        ) or note $@;

        ok( $data->base->$_isa( 'PDL' ),        'base is PDL' );
        ok( $data->mask->$_isa( 'PDLx::Mask' ), 'mask is PDLx::Mask' );

        pdl_is( $data->base,       pdl( 2, 3, 4 ), 'base values ok' );
        pdl_is( $data->mask->mask, pdl( 1, 1, 1 ), 'mask values ok' );
        is( $data->nvalid, 3, 'number of valid values' );
    };

    subtest "shorthand arrayref, no mask" => sub {
        my $data;

        ok(
            lives {
                $data = PDLx::MaskedData->new( [ 2, 3, 4 ] )
            },
            'construct'
        ) or note $@;

        ok( $data->base->$_isa( 'PDL' ),        'base is PDL' );
        ok( $data->mask->$_isa( 'PDLx::Mask' ), 'mask is PDLx::Mask' );

        pdl_is( $data->base,       pdl( 2, 3, 4 ), 'base values ok' );
        pdl_is( $data->mask->mask, pdl( 1, 1, 1 ), 'mask values ok' );
        is( $data->nvalid, 3, 'number of valid values' );
    };

    subtest "shorthand arrayref, Mask" => sub {
        my $data;

        ok(
            lives {
                $data = PDLx::MaskedData->new( [ 2, 3, 4 ],
                    PDLx::Mask->new( [ 1, 1, 1 ] ) )
            },
            'construct'
        ) or note $@;

        ok( $data->base->$_isa( 'PDL' ),        'base is PDL' );
        ok( $data->mask->$_isa( 'PDLx::Mask' ), 'mask is PDLx::Mask' );

        pdl_is( $data->base,       pdl( 2, 3, 4 ), 'base values ok' );
        pdl_is( $data->mask->mask, pdl( 1, 1, 1 ), 'mask values ok' );
        is( $data->nvalid, 3, 'number of valid values' );
    };

};


subtest "post-constructor data assignment" => sub {

    my $data;
    ok(
        lives {
            $data = PDLx::MaskedData->new(
                base         => [ 2, 3, 4 ],
                masked_value => 0,
                data_mask    => 1
            )
        },
        'construct'
    ) or note $@;

    $data->data( [ 2, 0, 4 ] );

    pdl_is( $data->data,       pdl( 2, 0, 4 ), 'effective  values ok' );
    pdl_is( $data->mask->mask, pdl( 1, 0, 1 ), 'mask values ok' );
    is( $data->nvalid, 2, 'number of valid values' );

};

subtest "post-constructor mask assignment" => sub {

    my $data;
    ok(
        lives {
            $data = PDLx::MaskedData->new( [ 2, 3, 4 ] )
        },
        'construct'
    ) or note $@;

    pdl_is( $data->data,       pdl( 2, 3, 4 ), 'effective values ok' );
    pdl_is( $data->mask->mask, pdl( 1, 1, 1 ), 'mask values ok' );
    is( $data->nvalid, 3, 'number of valid values' );

    my $old_mask  = $data->mask;
    my $old_token = $data->_token;

    $data->mask( [ 1, 0, 1 ] );

    # expect that the old mask has been unsubscribed from
    like(
        dies { $old_mask->unsubscribe( $old_token ) },
        qr/invalid token/,
        "verify unsubscription from old mask"
    );


    pdl_is( $data->data,       pdl( 2, 0, 4 ), 'effective  values ok' );
    pdl_is( $data->mask->mask, pdl( 1, 0, 1 ), 'mask values ok' );
    is( $data->nvalid, 2, 'number of valid values' );

};

subtest "post-constructor data bad methods" => sub {

    subtest 'setbadat' => sub {
        my $data;
        ok(
            lives {
                $data = PDLx::MaskedData->new(
                    base      => [ 2, 3, 4 ],
                    data_mask => 1,
                    mask      => [ 0, 1, 1 ],
                );
            },
            'construct'
        ) or note $@;

        $data->setbadat( 1 );

        pdl_is( $data->base, badat( 2,     'BAD', 4 ), 'base values ok' );
        pdl_is( $data->data, badat( 'BAD', 'BAD', 4 ), 'effective values ok' );
        pdl_is( $data->mask->mask, pdl( 0, 0, 1 ), 'mask values ok' );
        is( $data->nvalid, 1, 'number of valid values' );

    };

};

subtest "only data_mask" => sub {

    my $data;
    ok(
        lives {
            $data = PDLx::MaskedData->new(
                base         => [ 2, 3, 4 ],
                masked_value => 0,
                data_mask    => 1,
                apply_mask   => 0,
            )
        },
        'construct'
    ) or note $@;

    $data->data( [ 2, 0, 4 ] );

    pdl_is( $data->base,       pdl( 2, 0, 4 ), 'base values ok' );
    pdl_is( $data->data,       pdl( 2, 0, 4 ), 'effective values ok' );
    pdl_is( $data->mask->mask, pdl( 1, 0, 1 ), 'mask values ok' );
    is( $data->nvalid, 2, 'number of valid values' );

    $data->mask->mask( 0 );

    pdl_is( $data->base,       pdl( 2, 0, 4 ), 'base values ok' );
    pdl_is( $data->data,       pdl( 2, 0, 4 ), 'effective values ok' );
    pdl_is( $data->mask->mask, pdl( 0, 0, 0 ), 'mask values ok' );

    # now apply mask after the fact
    $data->apply_mask( 1 );

    pdl_is( $data->base, pdl( 2, 0, 4 ), 'base values ok' );
    pdl_is( $data->data, pdl( 0, 0, 0 ), 'effective values ok' );
};

subtest "secondary mask" => sub {

    my $pmask = PDLx::Mask->new( pdl( byte, 1, 1, 1 ) );
    pdl_is( $pmask->mask, pdl( 1, 1, 1 ), "primary mask initial value" );

    my $smask = PDLx::MaskedData->new(
        base       => pdl( byte, 0, 1, 0 ),
        mask       => $pmask,
        apply_mask => 0,
        data_mask  => 1
    );

    pdl_is( $smask->data, pdl( 0, 1, 0 ), "secondary mask initial value" );

    pdl_is( $pmask->mask, $smask->data,
        "primary mask tracks initial secondary mask" );

    $smask->set( 0, 1 );
    pdl_is( $smask->data, pdl( 1, 1, 0 ), "update secondary mask" );
    pdl_is(
        $pmask->mask,
        pdl( 1, 1, 0 ),
        "primary mask tracks updated secondary mask"
    );

    $pmask->set( 0, 0 );
    pdl_is( $pmask->base, pdl( 0, 1, 1 ), "update base primary mask" );
    pdl_is(
        $pmask->mask,
        pdl( 0, 1, 0 ),
        "effective primary mask tracks updated base mask"
    );
    pdl_is(
        $smask->data,
        pdl( 1, 1, 0 ),
        "secondary mask doesn't track primary mask"
    );

};

subtest "subscription follies" => sub {

    subtest "data directed" => sub {

        my $mask = PDLx::Mask->new( pdl( byte, 1, 0, 1, 1 ) );

        my $data = PDLx::MaskedData->new(
            base       => pdl( 1, 1, 0, 0 ),
            mask       => $mask,
            apply_mask => 1,
            data_mask  => 1,
        );

        pdl_is( $data->data, pdl( 1, 0, 0, 0 ),
            "effective data initial value" );
        pdl_is(
            $mask->mask,
            pdl( 1, 0, 0, 0 ),
            "mask tracks initial data mask"
        );

        $data->set( 2, 2 );
        pdl_is( $data->base, pdl( 1, 1, 2, 0 ), "base data updated value" );
        pdl_is( $data->data, pdl( 1, 0, 2, 0 ),
            "effective data updated value" );
        pdl_is(
            $mask->mask,
            pdl( 1, 0, 1, 0 ),
            "mask tracks updated data mask"
        );


        subtest "unsubscribe, no reset" => sub {

            # unsubscribe, keeping effective and base data separate; can't test
            # if that's true unless we peek behind the curtain

            $data->unsubscribe( reset_data_storage => 0 );
            is( 0+ $data->_has_shared_data_storage,
                0, "data storage still separate" );

            pdl_is( $data->data, $data->base, "effective data == base data" );
            pdl_is( $mask->mask, $mask->base, "effective mask == base mask" );

            $data->set( 0, 3 );
            pdl_is( $data->base, pdl( 3, 1, 2, 0 ), "updated base data value" );
            pdl_is( $data->data, $data->base, "effective data == base data" );
            pdl_is( $mask->mask, $mask->base, "effective mask == base mask" );

            $mask->set( 0, 0 );
            pdl_is( $mask->base, pdl( 0, 0, 1, 1 ), "updated base mask value" );
            pdl_is( $mask->mask, $mask->base, "effective mask == base mask" );
            pdl_is( $data->data, $data->base, "effective data == base data" );

        };


        subtest "re-subscribe" => sub {
            $data->subscribe;

            pdl_is(
                $mask->base,
                pdl( 0, 0, 1, 1 ),
                "base mask value unchanged"
            );
            pdl_is( $mask->mask, pdl( 0, 0, 1, 0 ), "mask tracks data mask" );

            pdl_is(
                $data->base,
                pdl( 3, 1, 2, 0 ),
                "base data value unchanged"
            );

            pdl_is(
                $data->data,
                pdl( 0, 0, 2, 0 ),
                "effective data updated value"
            );

        };

    };

    subtest "mask directed" => sub {

        my $mask = PDLx::Mask->new( [0] );

        my $data = PDLx::MaskedData->new( [1], $mask );

        # yeah, this ain't public.
        my $token = $data->_token;

        $mask->unsubscribe( $token );

        pdl_is(
            $data->data,
            pdl( [1] ),
            "data ignores mask after mask unsubscribes data"
        );

    };


};


my %OpTests = (

    '+=' => {
        op => sub { $_[0] += 1 },
    },

    '-=' => {
        op => sub { $_[0] -= 1 },
    },

    '/=' => {
        op => sub { $_[0] /= 2 },
    },

    '*=' => {
        op => sub { $_[0] *= 2 },
    },

    '%=' => {
        op => sub { $_[0] %= 2 },
    },

    '**=' => {
        op => sub { $_[0]**= 2 },
    },

    '<<=' => {
        op => sub { $_[0] <<= 2 },
    },

    '>>=' => {
        op => sub { $_[0] >>= 2 },
    },

    '.=' => {
        op => sub { $_[0] .= 2 },
    },

    '&=' => {
        op => sub { $_[0] &= 2 },
    },

    '|=' => {
        op => sub { $_[0] |= 2 },
    },

    '^=' => {
        op => sub { $_[0] ^= 2 },
    },

);


my @PDL_Overload_Ops = grep { defined overload::Method( 'PDL', $_ ) }
  grep { /=$/ }
  map { split( ' ', $_ ) } @{overload::ops}{ 'assign', 'binary', 'mutators' };

my %PDL_Overload_Ops = map { $_ => 1 } @PDL_Overload_Ops;

BAIL_OUT( "missing test for operator $_\n" )
  for grep { !defined $OpTests{$_} } @PDL_Overload_Ops;

BAIL_OUT( "test for operator not overloaded in PDL: $_\n" )
  for grep { !defined $PDL_Overload_Ops{$_} } keys %OpTests;

subtest 'overload assignment ops/methods' => sub {

    {
        # copying returns a normal piddle
        my $data = PDLx::MaskedData->new( [ 1, 0, 2 ], [ 0, 0, 1 ] );

        my $copy = $data->copy;

        ok( $copy->isa( 'PDL' ) && !$copy->isa( 'PDLx::Mask' ),
            '$data->copy => ordinary PDL' );

        pdl_is( $copy, pdl( 0, 0, 2 ), "copy returns effective data" );

        # operating on a data results in a normal piddle
        my $pdl = $data + 1;
        ok( $pdl->isa( 'PDL' ) && !$pdl->isa( 'PDLx::Mask' ),
            '$data + 1 => ordinary PDL' );

        pdl_is(
            $pdl,
            pdl( 1, 1, 3 ),
            '$data + 1 => operates on effective data'
        );
    }


    while ( my ( $op, $test ) = each %OpTests ) {

        subtest "$op, no upstream, no masked values" => sub {

            my $initial = pdl( 1, 0, 1 );

            my $expected = $test->{op}->( $initial->copy );

            my $data = PDLx::MaskedData->new( $initial );

            ok( lives { $test->{op}->( $data ) }, "evaluate" )
              or note $@;

            pdl_is( $data->base, $expected, "result" );
            if ( $data->dsum->$_isa( 'PDL' ) ) {
                pdl_is( $data->dsum, $expected->dsum, "dsum" );
            }
            else {
                is( $data->dsum, $expected->dsum, "dsum" );
            }
        };

        subtest "$op, upstream mask, mask value = 0" => sub {

            my $initial      = pdl( 1, 0, 1 );
            my $initial_mask = $initial != 0;

            my $expected_base = $test->{op}->( $initial->copy );
            my $expected_mask = $initial & ( $expected_base != 0 );
            my $expected_data = $expected_base * $expected_mask;

            my $data
              = PDLx::MaskedData->new( base => $initial, data_mask => 1 );

            pdl_is( $data->mask->mask, $initial_mask, "initial mask" );

            ok( lives { $test->{op}->( $data ) }, "evaluate" )
              or note $@;

            pdl_is( $data->base,       $expected_base, "expected result" );
            pdl_is( $data->mask->mask, $expected_mask, "expected mask" );
            pdl_is( $data->data,       $expected_data, "expected mask" );

            if ( $data->dsum->$_isa( 'PDL' ) ) {
                pdl_is( $data->dsum, $expected_data->dsum, "dsum" );
            }
            else {
                is( $data->dsum, $expected_data->dsum, "dsum" );
            }
        };
    }
};

done_testing;
