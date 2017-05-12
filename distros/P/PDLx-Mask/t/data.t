#!perl

use strict;
use warnings;

use Test::More;
use Test::Deep;

use Test::PDL qw[ is_pdl ];
use PDL::Lite;

use Safe::Isa;
use PDLx::Mask;
use PDLx::MaskedData;

use Test::Fatal;
use Scalar::Util qw[ refaddr ];

require 't/fix_devel_cover.pl';

subtest "constructor" => sub {

    like(
        exception { PDLx::MaskedData->new },
        qr/missing required/i,
        'no base, no mask'
    );

    like(
        exception { PDLx::MaskedData->new( mask => 0 ) },
        qr/missing required/i,
        'no base, mask'
    );

    like(
        exception { PDLx::MaskedData->new( base => 'foo', mask => 0 ) },
        qr/coercion (.*) failed/ix,
        'base not coercible'
    );

    like(
        exception { PDLx::MaskedData->new( base => 0, mask => 'foo' ) },
        qr/coercion (.*) failed/ix,
        'mask not coercible'
    );

    is( exception { PDLx::MaskedData->new( { base => 0 } ) }, undef,
        'hashref' );

    subtest "base, no mask" => sub {

        subtest "no upstream" => sub {

            my $data;

            is( exception { $data = PDLx::MaskedData->new( base => 0 ) },
                undef, "constructor", );

            ok( $data->mask->$_isa( 'PDLx::Mask' ), 'mask is PDLx::Mask' );

            cmp_deeply( $data->base->unpdl, [0], 'base values' );
            cmp_deeply( $data->mask->unpdl, [1], 'mask values' );

        };

        subtest "no upstream, upstream bad, no masked values" => sub {

            my $data;
            my $pdl = pdl( 0, 1 );
            $pdl->badflag( 1 );

            is(
                exception {
                    $data
                      = PDLx::MaskedData->new( base => $pdl, data_mask => 1 )
                },
                undef,
                "constructor",
            );

            ok( $data->mask->$_isa( 'PDLx::Mask' ), 'mask is PDLx::Mask' );

            cmp_deeply( $data->base->unpdl, [ 0, 1 ], 'base values' );
            cmp_deeply( $data->mask->unpdl, [ 1, 1 ], 'mask values' );

        };

        subtest "no upstream, upstream bad, masked values" => sub {

            my $data;

            my $pdl = pdl( 0, 1, 2 );
            $pdl->setbadat( 0 );

            is(
                exception {
                    $data = PDLx::MaskedData->new(
                        base      => $pdl,
                        data_mask => 1,
                        mask      => [ 1, 1, 0 ],
                      )
                },
                undef,
                "constructor",
            );

            ok( $data->mask->$_isa( 'PDLx::Mask' ), 'mask is PDLx::Mask' );

            cmp_deeply( $data->base->unpdl, [ 'BAD', 1, 2 ], 'base values' );
            cmp_deeply(
                $data->_data_mask->unpdl,
                [ 0, 1, 1 ],
                'data mask values'
            );
            cmp_deeply( $data->mask->unpdl, [ 0, 1, 0 ], 'mask values' );
            cmp_deeply( $data->unpdl, [ 'BAD', 1, 'BAD' ], 'data values' );
            is( $data->nvalid, 1, 'number of valid values' );

        };

        subtest "no upstream, upstream value, no masked values" => sub {

            my $data;
            my $pdl = pdl( 1 );

            is(
                exception {
                    $data = PDLx::MaskedData->new(
                        base       => $pdl,
                        data_mask  => 1,
                        mask_value => 0
                      )
                },
                undef,
                "constructor",
            );

            ok( $data->mask->$_isa( 'PDLx::Mask' ), 'mask is PDLx::Mask' );

            cmp_deeply( $data->base->unpdl, [1], 'base values' );
            cmp_deeply( $data->mask->unpdl, [1], 'mask values' );
            is( $data->nvalid, 1, 'number of valid values' );
        };

        subtest "no upstream, upstream value, masked values" => sub {

            my $data;
            my $pdl = pdl( 0 );

            is(
                exception {
                    $data = PDLx::MaskedData->new(
                        base       => $pdl,
                        data_mask  => 1,
                        mask_value => 0
                      )
                },
                undef,
                "constructor",
            );

            ok( $data->mask->$_isa( 'PDLx::Mask' ), 'mask is PDLx::Mask' );

            cmp_deeply( $data->base->unpdl, [0], 'base values' );
            cmp_deeply( $data->mask->unpdl, [0], 'mask values' );
            is( $data->nvalid, 0, 'number of valid values' );
        };

    };


    subtest "scalar, scalar" => sub {
        my $data;

        is(
            exception { $data = PDLx::MaskedData->new( base => 3, mask => 4 ) },
            undef, 'construct'
        );

        ok( $data->base->$_isa( 'PDL' ),        'base is PDL' );
        ok( $data->mask->$_isa( 'PDLx::Mask' ), 'mask is PDLx::Mask' );

        cmp_deeply( $data->base->unpdl, [3], 'base values' );
        cmp_deeply( $data->mask->unpdl, [4], 'mask values' );
        is( $data->nvalid, 1, 'number of valid values' );

    };

    subtest "scalar, Mask" => sub {
        my $data;

        is(
            exception {
                $data = PDLx::MaskedData->new(
                    base => 3,
                    mask => PDLx::Mask->new( 4 ) )
            },
            undef,
            'construct'
        );

        ok( $data->base->$_isa( 'PDL' ),        'base is PDL' );
        ok( $data->mask->$_isa( 'PDLx::Mask' ), 'mask is PDLx::Mask' );

        cmp_deeply( $data->base->unpdl, [3], 'base values' );
        cmp_deeply( $data->mask->unpdl, [4], 'mask values' );
        is( $data->nvalid, 1, 'number of valid values' );

    };

    subtest "arrayref, arrayref" => sub {
        my $data;

        is(
            exception {
                $data = PDLx::MaskedData->new(
                    base => [ 2, 3, 4 ],
                    mask => [ 1, 1, 1 ] )
            },
            undef,
            'construct'
        );

        ok( $data->base->$_isa( 'PDL' ),        'base is PDL' );
        ok( $data->mask->$_isa( 'PDLx::Mask' ), 'mask is PDLx::Mask' );

        cmp_deeply( $data->base->unpdl, [ 2, 3, 4 ], 'base values ok' );
        cmp_deeply( $data->mask->unpdl, [ 1, 1, 1 ], 'mask values ok' );
        is( $data->nvalid, 3, 'number of valid values' );
    };

    subtest "shorthand arrayref, no mask" => sub {
        my $data;

        is(
            exception {
                $data = PDLx::MaskedData->new( [ 2, 3, 4 ] )
            },
            undef,
            'construct'
        );

        ok( $data->base->$_isa( 'PDL' ),        'base is PDL' );
        ok( $data->mask->$_isa( 'PDLx::Mask' ), 'mask is PDLx::Mask' );

        cmp_deeply( $data->base->unpdl, [ 2, 3, 4 ], 'base values ok' );
        cmp_deeply( $data->mask->unpdl, [ 1, 1, 1 ], 'mask values ok' );
        is( $data->nvalid, 3, 'number of valid values' );
    };

    subtest "shorthand arrayref, Mask" => sub {
        my $data;

        is(
            exception {
                $data = PDLx::MaskedData->new( [ 2, 3, 4 ],
                    PDLx::Mask->new( [ 1, 1, 1 ] ) )
            },
            undef,
            'construct'
        );

        ok( $data->base->$_isa( 'PDL' ),        'base is PDL' );
        ok( $data->mask->$_isa( 'PDLx::Mask' ), 'mask is PDLx::Mask' );

        cmp_deeply( $data->base->unpdl, [ 2, 3, 4 ], 'base values ok' );
        cmp_deeply( $data->mask->unpdl, [ 1, 1, 1 ], 'mask values ok' );
        is( $data->nvalid, 3, 'number of valid values' );
    };

};


subtest "post-constructor data assignment" => sub {

    my $data;
    is(
        exception {
            $data = PDLx::MaskedData->new(
                base         => [ 2, 3, 4 ],
                masked_value => 0,
                data_mask    => 1
              )
        },
        undef,
        'construct'
    );

    $data->data( [ 2, 0, 4 ] );

    cmp_deeply( $data->unpdl,       [ 2, 0, 4 ], 'effective  values ok' );
    cmp_deeply( $data->mask->unpdl, [ 1, 0, 1 ], 'mask values ok' );
    is( $data->nvalid, 2, 'number of valid values' );

};

subtest "post-constructor mask assignment" => sub {

    my $data;
    is(
        exception {
            $data = PDLx::MaskedData->new( [ 2, 3, 4 ] )
        },
        undef,
        'construct'
    );

    cmp_deeply( $data->unpdl,       [ 2, 3, 4 ], 'effective values ok' );
    cmp_deeply( $data->mask->unpdl, [ 1, 1, 1 ], 'mask values ok' );
    is( $data->nvalid, 3, 'number of valid values' );

    my $old_mask  = $data->mask;
    my $old_token = $data->_token;

    $data->mask( [ 1, 0, 1 ] );

    # expect that the old mask has been unsubscribed from
    like(
        exception { $old_mask->unsubscribe( $old_token ) },
        qr/invalid token/,
        "verify unsubscription from old mask"
    );


    cmp_deeply( $data->unpdl,       [ 2, 0, 4 ], 'effective  values ok' );
    cmp_deeply( $data->mask->unpdl, [ 1, 0, 1 ], 'mask values ok' );
    is( $data->nvalid, 2, 'number of valid values' );

};

subtest "post-constructor data bad methods" => sub {

    subtest 'setbadat' => sub {
        my $data;
        is(
            exception {
                $data = PDLx::MaskedData->new(
                    base      => [ 2, 3, 4 ],
                    data_mask => 1,
                    mask      => [ 0, 1, 1 ],
                );
            },
            undef,
            'construct'
        );

        $data->setbadat( 1 );

        cmp_deeply( $data->base->unpdl, [ 2, 'BAD', 4 ], 'base values ok' );
        cmp_deeply( $data->unpdl, [ 'BAD', 'BAD', 4 ], 'effective values ok' );
        cmp_deeply( $data->mask->unpdl, [ 0, 0, 1 ], 'mask values ok' );
        is( $data->nvalid, 1, 'number of valid values' );

    };

};

subtest "only data_mask" => sub {

    my $data;
    is(
        exception {
            $data = PDLx::MaskedData->new(
                base         => [ 2, 3, 4 ],
                masked_value => 0,
                data_mask    => 1,
                apply_mask   => 0,
              )
        },
        undef,
        'construct'
    );

    $data->data( [ 2, 0, 4 ] );

    cmp_deeply( $data->base->unpdl, [ 2, 0, 4 ], 'base values ok' );
    cmp_deeply( $data->unpdl,       [ 2, 0, 4 ], 'effective values ok' );
    cmp_deeply( $data->mask->unpdl, [ 1, 0, 1 ], 'mask values ok' );
    is( $data->nvalid, 2, 'number of valid values' );

    $data->mask->mask( 0 );

    cmp_deeply( $data->base->unpdl, [ 2, 0, 4 ], 'base values ok' );
    cmp_deeply( $data->unpdl,       [ 2, 0, 4 ], 'effective values ok' );
    cmp_deeply( $data->mask->unpdl, [ 0, 0, 0 ], 'mask values ok' );

    # now apply mask after the fact
    $data->apply_mask( 1 );

    cmp_deeply( $data->base->unpdl, [ 2, 0, 4 ], 'base values ok' );
    cmp_deeply( $data->unpdl,       [ 0, 0, 0 ], 'effective values ok' );
};

subtest "secondary mask" => sub {

    my $pmask = PDLx::Mask->new( pdl( byte, 1, 1, 1 ) );
    cmp_deeply( $pmask->unpdl, [ 1, 1, 1 ], "primary mask initial value" );

    my $smask = PDLx::MaskedData->new(
        base       => pdl( byte, 0, 1, 0 ),
        mask       => $pmask,
        apply_mask => 0,
        data_mask  => 1
    );

    cmp_deeply( $smask->unpdl, [ 0, 1, 0 ], "secondary mask initial value" );

    cmp_deeply( $pmask->unpdl, $smask->unpdl,
        "primary mask tracks initial secondary mask" );

    $smask->set( 0, 1 );
    cmp_deeply( $smask->unpdl, [ 1, 1, 0 ], "update secondary mask" );
    cmp_deeply(
        $pmask->unpdl,
        [ 1, 1, 0 ],
        "primary mask tracks updated secondary mask"
    );

    $pmask->set( 0, 0 );
    cmp_deeply( $pmask->base->unpdl, [ 0, 1, 1 ], "update base primary mask" );
    cmp_deeply(
        $pmask->unpdl,
        [ 0, 1, 0 ],
        "effective primary mask tracks updated base mask"
    );
    cmp_deeply(
        $smask->unpdl,
        [ 1, 1, 0 ],
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

        cmp_deeply(
            $data->unpdl,
            [ 1, 0, 0, 0 ],
            "effective data initial value"
        );
        cmp_deeply(
            $mask->unpdl,
            [ 1, 0, 0, 0 ],
            "mask tracks initial data mask"
        );

        $data->set( 2, 2 );
        cmp_deeply(
            $data->base->unpdl,
            [ 1, 1, 2, 0 ],
            "base data updated value"
        );
        cmp_deeply(
            $data->unpdl,
            [ 1, 0, 2, 0 ],
            "effective data updated value"
        );
        cmp_deeply(
            $mask->unpdl,
            [ 1, 0, 1, 0 ],
            "mask tracks updated data mask"
        );


        subtest "unsubscribe, no reset" => sub {

            # unsubscribe, keeping effective and base data separate; can't test
            # if that's true unless we peek behind the curtain

            $data->unsubscribe( reset_data_storage => 0 );
            is( 0 + $data->_has_shared_data_storage,
                0, "data storage still separate" );

            cmp_deeply( $data->unpdl, $data->base->unpdl,
                "effective data == base data" );
            cmp_deeply( $mask->unpdl, $mask->base->unpdl,
                "effective mask == base mask" );

            $data->set( 0, 3 );
            cmp_deeply(
                $data->base->unpdl,
                [ 3, 1, 2, 0 ],
                "updated base data value"
            );
            cmp_deeply( $data->unpdl, $data->base->unpdl,
                "effective data == base data" );
            cmp_deeply( $mask->unpdl, $mask->base->unpdl,
                "effective mask == base mask" );

            $mask->set( 0, 0 );
            cmp_deeply(
                $mask->base->unpdl,
                [ 0, 0, 1, 1 ],
                "updated base mask value"
            );
            cmp_deeply( $mask->unpdl, $mask->base->unpdl,
                "effective mask == base mask" );
            cmp_deeply( $data->unpdl, $data->base->unpdl,
                "effective data == base data" );

        };


        subtest "re-subscribe" => sub {
            $data->subscribe;

            cmp_deeply(
                $mask->base->unpdl,
                [ 0, 0, 1, 1 ],
                "base mask value unchanged"
            );
            cmp_deeply( $mask->unpdl, [ 0, 0, 1, 0 ], "mask tracks data mask" );

            cmp_deeply(
                $data->base->unpdl,
                [ 3, 1, 2, 0 ],
                "base data value unchanged"
            );

            cmp_deeply(
                $data->unpdl,
                [ 0, 0, 2, 0 ],
                "effective data updated value"
            );

        };

    };

    subtest "mask directed" => sub {

        my $mask = PDLx::Mask->new( [ 0 ] );

        my $data = PDLx::MaskedData->new( [ 1 ], $mask );

	# yeah, this ain't public.
	my $token = $data->_token;

	$mask->unsubscribe( $token );

	cmp_deeply( $data->unpdl, [ 1 ] , "data ignores mask after mask unsubscribes data" );

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

        cmp_deeply( $copy->unpdl, [ 0, 0, 2 ], "copy returns effective data" );

        # operating on a data results in a normal piddle
        my $pdl = $data + 1;
        ok( $pdl->isa( 'PDL' ) && !$pdl->isa( 'PDLx::Mask' ),
            '$data + 1 => ordinary PDL' );

        cmp_deeply(
            $pdl->unpdl,
            [ 1, 1, 3 ],
            '$data + 1 => operates on effective data'
        );
    }


    while ( my ( $op, $test ) = each %OpTests ) {

        subtest "$op, no upstream, no masked values" => sub {

            my $initial = pdl( 1, 0, 1 );

            my $expected = $test->{op}->( $initial->copy );

            my $data = PDLx::MaskedData->new( $initial );

            is( exception { $test->{op}->( $data ) }, undef, "evaluate" );

            cmp_deeply( $data->base->unpdl, $expected->unpdl, "result" );

            is( $data->dsum, $expected->dsum, "dsum" );

        };

        subtest "$op, upstream mask, mask value = 0" => sub {

            my $initial = pdl( 1, 0, 1 );
            my $initial_mask = $initial != 0;

            my $expected_base = $test->{op}->( $initial->copy );
            my $expected_mask = $initial & ( $expected_base != 0 );
            my $expected_data = $expected_base * $expected_mask;

            my $data
              = PDLx::MaskedData->new( base => $initial, data_mask => 1 );

            cmp_deeply( $data->mask->unpdl, $initial_mask->unpdl,
                "initial mask" );

            is( exception { $test->{op}->( $data ) }, undef, "evaluate" );

            cmp_deeply( $data->base->unpdl, $expected_base->unpdl,
                "expected result" );
            cmp_deeply( $data->mask->unpdl, $expected_mask->unpdl,
                "expected mask" );
            cmp_deeply( $data->unpdl, $expected_data->unpdl, "expected mask" );

            is( $data->dsum, $expected_data->dsum, "dsum" );

        };


    }

};

done_testing;
