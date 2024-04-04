#!perl

use Test2::V0;
use Test2::Tools::Compare qw[ object call ];

use PDL::Algorithm::Center qw[ sigma_clip ];

use PDL::Lite;
use PDL::Core  qw( pdl zeroes );
use PDL::Ufunc qw( dsum dsumover );
use PDL::IO::FITS;
use Scalar::Util qw( blessed );

use Data::Dump 'pp';

use Hash::Wrap;

sub eclass ($) {
    return join( '::', 'PDL::Algorithm::Center::Failure', @_ );
}

# log iterations for debugging poiposes
sub logit {
    my %msg = %{ shift() };
    $msg{center} = [ PDL::Core::topdl( $msg{center} )->list ];
    note pp \%msg;
}

# need to distinguish between PDL < 2.056, where dsum returns a Perl
# scalar and PDL >= 2.056, where dsum returns an ndarray.  This complicates
# checks for e.g. distance
sub my_float {
    my $expected = shift;

    return validator(
        sub {
            my $got = $_;
            my $ref;
            $got = $got->at if defined( $ref = blessed $got ) && $ref eq 'PDL';
            !!float( $expected )->run( convert => sub { $_[0] } );
        } );
}

sub to_scalar {
    my $what = shift;
    my $ref  = blessed $what;
    return ( defined( $ref ) && $ref eq 'PDL' ) ? $what->sclr : $what;
}

########################################
# interface

my %req = ( nsigma => 1.5, dtol => 1.0 );

# coordinates
subtest "coords" => sub {

    my $e;

    isa_ok( $e = dies { sigma_clip( %req, coords => PDL->null ) }, [ eclass( 'parameter' ) ], 'null' );

    isa_ok( $e = dies { sigma_clip( %req, coords => PDL->zeroes( 0 ) ) },
        [ eclass( 'parameter' ) ], 'empty' );

    isa_ok( $e = dies { sigma_clip( %req, coords => 'scalar' ) }, [ eclass( 'parameter' ) ], 'scalar' );

    isa_ok(
        $e = dies { sigma_clip( %req, coords => ['scalar'] ) },
        [ eclass( 'parameter' ) ],
        'array element not piddle'
    );

    isa_ok(
        $e = dies {
            sigma_clip( %req, coords => [ pdl( 1 ), pdl( 1, 2 ), pdl( 1 ) ] )
        },
        [ eclass( 'parameter' ) ],
        'unequal number of elements'
    );

    isa_ok(
        $e = dies {
            sigma_clip( %req, coords => [ pdl( [ 1, 2 ], [ 3, 4 ] ) ] )
        },
        [ eclass( 'parameter' ) ],
        'not 1D'
    );

    ok( lives { sigma_clip( %req, coords => pdl( 1, 2 ) ) }, "pdl(1, 2)", )
      or note( $@ );

    ok( lives { sigma_clip( %req, coords => [ pdl( 1, 2 ) ] ) }, "[ pdl(1, 2) ]", ) or note( $@ );

    ok( lives { sigma_clip( %req, coords => pdl( 1 ) ) }, "pdl(1)", )
      or note( $@ );

};

subtest "center" => sub {

    isa_ok(
        dies {
            sigma_clip(
                %req,
                coords => pdl( 1 ),
                center => 'foo'
            )
        },
        [ eclass( 'parameter' ) ],
        'center not a 1D piddle'
    );

    ok(
        lives {
            sigma_clip(
                %req,
                coords => pdl( [1], [2] ),
                center => pdl( 1.5 ),
            )
        },
        'center a 1D piddle'
    ) or note $@;

    ok(
        lives {
            sigma_clip(
                %req,
                coords => pdl( [1], [2] ),
                center => [1.5],
            )
        },
        'center a arrayref'
    ) or note $@;

};

subtest "weight" => sub {

    isa_ok(
        dies {
            sigma_clip( %req, weight => [] );
        },
        [ eclass( 'parameter' ) ],
        'wrong type'
    );

    ok(
        lives {
            sigma_clip( %req, weight => 1 );
        },
        'pdl(1)'
    ) or note $@;

};

foreach my $field ( 'weight', 'mask' ) {

    subtest "coords + $field" => sub {

        isa_ok(
            dies {
                sigma_clip(
                    %req,
                    coords => [ pdl( 1, 2, 3 ), pdl( 3, 4, 5 ) ],
                    $field => pdl( 1 ),
                )
            },
            [ eclass( 'parameter' ) ],
            'incorrect dimensions'
        );

        ok(
            lives {
                sigma_clip(
                    %req,
                    coords => [ pdl( 1, 2, 3 ), pdl( 3, 4, 5 ) ],
                    $field => pdl( 1, 2, 3 ),
                )
            },
            'matched dimensions'
        ) or note $@;

    };

}

subtest "!( coords || weight)" => sub {

    isa_ok( dies { sigma_clip( %req, ) }, [ eclass( 'parameter' ) ], 'neither coords nor weight' );

};

subtest 'log' => sub {

    isa_ok(
        dies {
            sigma_clip(
                %req,
                coords => pdl( 1 ),
                log    => 'string',
            )
        },
        [ eclass( 'parameter' ) ],
        'log = string'
    );

};

for my $field ( qw( clip nsigma dtol ) ) {

    subtest $field => sub {

        isa_ok(
            dies {
                sigma_clip( %req, coords => pdl( 1 ), $field => 'foo' )
            },
            [ eclass( 'parameter' ) ],
            qq/$field = string/
        );

        isa_ok(
            dies {
                sigma_clip( %req, coords => pdl( 1 ), $field => -1 )
            },
            [ eclass( 'parameter' ) ],
            qq/$field = -1/
        );

        isa_ok(
            dies {
                sigma_clip( %req, coords => pdl( 1 ), $field => 0 )
            },
            [ eclass( 'parameter' ) ],
            qq/$field = 0/
        );

        ok(
            lives {
                sigma_clip( %req, coords => pdl( 1, 1 ), $field => 1 )
            },
            qq/$field = 1/
        ) or note $@;

    };
}

########################################
# operations

my $coords_cache;

sub _generate_sample {

    my %attr;

    $attr{nelem} = 100000;

    $coords_cache //= do {
        my $data = 't/data/rng.fits';

        if ( -f $data ) {
            PDL::IO::FITS::rfits( $data );
        }

        else {
            require PDL::GSL::RNG;

            # so tests are reproducible
            my $rng = PDL::GSL::RNG->new( 'taus' );
            $rng->set_seed( 1 );
            $coords_cache = $rng->ran_bivariate_gaussian( 10, 8, 0.5, $attr{nelem} );
            $coords_cache->wfits( $data );
            $coords_cache;
        }
    };

    $attr{coords} = $coords_cache->copy;

    # generate a bunch of coordinates
    $attr{initial_center} = pdl( 0.5, 0.5 );
    $attr{average_center} = $attr{coords}->xchg( 0, 1 )->average->unpdl;

    # calculate sigma for those inside of a radius of 10
    $attr{mask}
      = dsumover( ( $attr{coords} - $attr{initial_center} )**2 ) < 100;
    $attr{inside}
      = $attr{coords}->xchg( 0, 1 )->whereND( $attr{mask} )->xchg( 0, 1 );

    $attr{ninside} = $attr{inside}->dim( 1 );
    $attr{sigma}   = sqrt( dsum( ( $attr{inside} - $attr{initial_center} )**2 ) / $attr{ninside} );

    $attr{center} = [ 0.0126755884280886, 0.0337090322699186, ];

    $attr{dist} = 0;

    return wrap_hash( \%attr );
}

# let's try with no clip and no initial center
subtest 'coords, no clip, no initial center' => sub {

    my $sample = _generate_sample();

    my $results = sigma_clip(
        coords  => $sample->coords,
        dtol    => 0.00001,
        iterlim => 100,
        nsigma  => 1.5,

        # log => sub { require DDP; $_[0]->center( $_[0]->center->unpdl ); \&DDP::p( $_[0] ) },
    );

    ok( $results->success, "successful centering" ) or note $results->error;

    # make sure iteration 0 agrees with the above calculations
    # Test2::V0 can't handle objects which overload &&.
    my $iter0 = $results->iterations->[0];
    $iter0->center( $iter0->center->unpdl );
    is(
        $iter0,
        object {
            call nelem        => $sample->nelem;
            call total_weight => $sample->nelem;
            call center       => array {
                item float( $sample->average_center->[0] );
                item float( $sample->average_center->[1] );
                end;
            };
            call sigma => D();
            call dist  => U();
            call clip  => U();
        },
        "iteration 0",
    );

    # ensure  the last one agrees with previous fiducial runs, to see
    # if something has broken

    # Test2::V0 can't handle objects which overload &&.
    $results->center( $results->center->unpdl );
    #<<< notidy
    is(
        $results,
        object {
            call iter => 70;
            call dist => my_float( $sample->dist );
            call nelem => 43597;
            call total_weight => 43597;
            call center => array {
                item float( $sample->center->[0] );
                item float( $sample->center->[1] );
                end;
            };
        },
        "iteration -1",
    );
    #>>> notidy
};

# let's try with no clip and no initial center
subtest 'coords, no clip, initial center = [X,Y]' => sub {

    my $sample = _generate_sample();

    my $results = sigma_clip(
        coords  => $sample->coords,
        center  => $sample->initial_center->unpdl,
        dtol    => 0.00001,
        iterlim => 100,
        nsigma  => 1.5,

        # log => sub { require DDP; $_[0]->center( $_[0]->center->unpdl ); \&DDP::p( $_[0] ) },
    );

    ok( $results->success, "successful centering" ) or note $results->error;

    # make sure iteration 0 agrees with the above calculations
    # Test2::V0 can't handle objects which overload &&.
    my $iter0 = $results->iterations->[0];
    $iter0->center( $iter0->center->unpdl );
    is(
        $iter0,
        object {
            call nelem        => $sample->nelem;
            call total_weight => $sample->nelem;
            call center       => array {
                item float( $sample->initial_center->at( 0 ) );
                item float( $sample->initial_center->at( 1 ) );
                end;
            };
            call sigma => D();
            call dist  => U();
            call clip  => U();
        },
        "iteration 0",
    );

    # ensure  the last one agrees with previous fiducial runs, to see
    # if something has broken

    # Test2::V0 can't handle objects which overload &&.
    $results->center( $results->center->unpdl );
    #<<< notidy
    is(
        $results,
        object {
            call iter => 70;
            call dist => my_float( $sample->dist );
            call nelem => 43597;
            call total_weight => 43597;
            call center => array {
                item float( $sample->center->[0] );
                item float( $sample->center->[1] );
                end;
            };
        },
        "iteration -1",
    );
    #>>> notidy
};

subtest 'coords, no clip, initial center = [ X, undef]' => sub {

    my $sample = _generate_sample();

    my $results = sigma_clip(
        center  => [ $sample->initial_center->at( 0 ), undef ],
        coords  => $sample->coords,
        dtol    => 0.00001,
        iterlim => 100,
        nsigma  => 1.5,

        # log => sub { require DDP; $_[0]->center( $_[0]->center->unpdl ); \&DDP::p( $_[0] ) },
    );

    ok( $results->success, "successful centering" ) or note $results->error;

    # make sure iteration 0 agrees with the above calculations
    # Test2::V0 can't handle objects which overload &&.
    my $iter0 = $results->iterations->[0];
    $iter0->center( $iter0->center->unpdl );
    is(
        $iter0,
        object {
            call nelem        => $sample->nelem;
            call total_weight => $sample->nelem;
            call center       => array {
                item float( $sample->initial_center->at( 0 ) );
                item float( $sample->average_center->[1] );
                end;
            };
            call sigma => D();
            call dist  => U();
            call clip  => U();
        },
        "iteration 0",
    );

    # ensure  the last one agrees with previous fiducial runs, to see
    # if something has broken

    # Test2::V0 can't handle objects which overload &&.
    $results->center( $results->center->unpdl );
    #<<< notidy
    is(
        $results,
        object {
            call iter => 70;
            call dist => my_float( $sample->dist );
            call nelem => 43597;
            call total_weight => 43597;
            call center => array {
                item float( $sample->center->[0] );
                item float( $sample->center->[1] );
                end;
            };
        },
        "iteration -1",
    );
    #>>> notidy
};

subtest 'coords, no clip, initial center => [undef,Y]' => sub {

    my $sample = _generate_sample();

    my $results = sigma_clip(
        center  => [ undef, $sample->initial_center->at( 1 ) ],
        coords  => $sample->coords,
        dtol    => 0.00001,
        iterlim => 100,
        nsigma  => 1.5,

        # log => sub { require DDP; $_[0]->center( $_[0]->center->unpdl ); \&DDP::p( $_[0] ) },
    );

    ok( $results->success, "successful centering" ) or note $results->error;

    # make sure iteration 0 agrees with the above calculations
    # Test2::V0 can't handle objects which overload &&.
    my $iter0 = $results->iterations->[0];
    $iter0->center( $iter0->center->unpdl );
    is(
        $iter0,
        object {
            call nelem        => $sample->nelem;
            call total_weight => $sample->nelem;
            call center       => array {
                item float( $sample->average_center->[0] );
                item float( $sample->initial_center->at( 1 ) );
                end;
            };
            call sigma => D();
            call dist  => U();
            call clip  => U();
        },
        "iteration 0",
    );

    # ensure  the last one agrees with previous fiducial runs, to see
    # if something has broken

    # Test2::V0 can't handle objects which overload &&.
    $results->center( $results->center->unpdl );
    #<<< notidy
    is(
        $results,
        object {
            call iter => 70;
            call dist => my_float( $sample->dist );
            call nelem => 43597;
            call total_weight => 43597;
            call center => array {
                item float( $sample->center->[0] );
                item float( $sample->center->[1] );
                end;
            };
        },
        "iteration -1",
    );
    #>>> notidy
};

subtest 'coords, no clip, initial center => [undef, undef]' => sub {

    my $sample = _generate_sample();

    my $results = sigma_clip(
        center  => [ undef, undef ],
        coords  => $sample->coords,
        dtol    => 0.00001,
        iterlim => 100,
        nsigma  => 1.5,

        # log => sub { require DDP; $_[0]->center( $_[0]->center->unpdl ); \&DDP::p( $_[0] ) },
    );

    ok( $results->success, "successful centering" ) or note $results->error;

    # make sure iteration 0 agrees with the above calculations
    # Test2::V0 can't handle objects which overload &&.
    my $iter0 = $results->iterations->[0];
    $iter0->center( $iter0->center->unpdl );
    is(
        $iter0,
        object {
            call nelem        => $sample->nelem;
            call total_weight => $sample->nelem;
            call center       => array {
                item float( $sample->average_center->[0] );
                item float( $sample->average_center->[1] );
                end;
            };
            call sigma => D();
            call dist  => U();
            call clip  => U();
        },
        "iteration 0",
    );

    # ensure  the last one agrees with previous fiducial runs, to see
    # if something has broken

    # Test2::V0 can't handle objects which overload &&.
    $results->center( $results->center->unpdl );
    #<<< notidy
    is(
        $results,
        object {
            call iter => 70;
            call dist => my_float( $sample->dist );
            call nelem => 43597;
            call total_weight => 43597;
            call center => array {
                item float( $sample->center->[0] );
                item float( $sample->center->[1] );
                end;
            };
        },
        "iteration -1",
    );
    #>>> notidy
};

# let's try clipping!
subtest 'coords + clip results' => sub {

    my $sample = _generate_sample();

    my $results = sigma_clip(
        coords  => $sample->coords,
        center  => $sample->initial_center,
        clip    => 10,
        dtol    => 0.00001,
        iterlim => 100,
        nsigma  => 1.5,

        # log => sub { require DDP; $_[0]->center( $_[0]->center->unpdl ); \&DDP::p( $_[0] ) },
    );

    ok( $results->success, "successful centering" ) or note $results->error;

    # make sure iteration 0 agrees with the above calculations
    is(
        $results->iterations->[0],
        object {
            call sigma        => my_float( $sample->sigma );
            call nelem        => $sample->ninside;
            call total_weight => $sample->ninside;
            call dist         => U();
            call clip         => 10;
        },
        "iteration 0",
    );

    # and that the last one agrees with previous fiducial runs, to see
    # if something has broken

    # Test2::V0 can't handle objects which overload &&.
    $results->center( $results->center->unpdl );
    #<<< notidy
    is(
        $results,
        object {
            call iter => 56;
            call dist => my_float( $sample->dist );
            call nelem => 43597;
            call total_weight => 43597;
            call center => array {
                item float( $sample->center->[0] );
                item float( $sample->center->[1] );
                end;
            };
        },
        "iteration -1",
    );
    #>>> notidy

};

# let's try masking!
subtest 'coords + mask results' => sub {

    my $sample = _generate_sample();

    my $results = sigma_clip(
        coords  => $sample->coords,
        center  => $sample->initial_center,
        mask    => $sample->mask,
        iterlim => 100,
        dtol    => 0.00001,
        nsigma  => 1.5,

        # log => sub { require DDP; $_[0]->center( $_[0]->center->unpdl ); \&DDP::p( $_[0] ) },
    );

    ok( $results->success, "successful centering" ) or note $results->error;

    # make sure iteration 0 agrees with the above calculations
    is(
        $results->{iterations}[0],
        object {
            call sigma        => my_float( $sample->sigma );
            call nelem        => $sample->ninside;
            call total_weight => $sample->ninside;
            call dist         => U();
            call clip         => U();
        },
        "iteration 0",
    );

    # Test2::V0 can't handle objects which overload &&.
    $results->center( $results->center->unpdl );
    #<<< notidy
    is(
        $results,
        object {
            call iter => 56;
            call dist => my_float( $sample->dist );
            call nelem => 43597;
            call total_weight => 43597;
            call center => array {
                item float( $sample->center->[0] );
                item float( $sample->center->[1] );
                end;
            };
        },
        "iteration -1",
    );
    #>>> notidy

};

# Let's try weighting!

subtest 'coords + clip + weight results' => sub {

    my $sample = _generate_sample();

    my $weight            = zeroes( $sample->nelem ) + 2;
    my $inside_weight     = $weight->where( $sample->mask );
    my $inside_weight_sum = to_scalar( $inside_weight->dsum );

    $sample->sigma(
        sqrt(
            dsum( $inside_weight * dsumover( ( $sample->inside - $sample->initial_center )**2 ) )
              / $inside_weight_sum
        ) );

    my $results = sigma_clip(
        coords  => $sample->coords,
        center  => $sample->initial_center,
        nsigma  => 1.5,
        clip    => 10,
        iterlim => 100,
        dtol    => 0.00001,
        weight  => $weight,
    );

    # make sure iteration 0 agrees with the above calculations
    is(
        $results->{iterations}[0],
        object {
            call sigma        => my_float( $sample->sigma );
            call nelem        => $sample->ninside;
            call total_weight => $inside_weight_sum;
            call dist         => U();
            call clip         => 10;
        },
        "iteration 0",
    );

    # Test2::V0 can't handle objects which overload &&.
    $results->center( $results->center->unpdl );
    #<<< notidy
    is(
        $results,
        object {
            call iter => 56;
            call dist => my_float( $sample->dist );
            call nelem => 43597;
            call total_weight => 43597 * 2;
            call center => array {
                item float( $sample->center->[0] );
                item float( $sample->center->[1] );
                end;
            };
        },
        "iteration -1",
    );
    #>>> notidy

};

subtest serialize => sub {

    my $result;
    ok(
        lives {
            $result = sigma_clip(
                %req,
                coords => pdl( [1], [2] ),
                center => pdl( 1.5 ),
            );
        },
        'center a 1D piddle'
    ) or note $@;

    is(
        $result,
        object {
            call center     => object { call sclr => 1.5 };
            call clip       => 0.75;
            call dist       => 0;
            call error      => U();
            call iter       => 1;
            call iterations => array {
                item object {
                    call center       => object { call sclr => 1.5 };
                    call clip         => U();
                    call dist         => U();
                    call iter         => 0;
                    call nelem        => 2;
                    call sigma        => 0.5;
                    call total_weight => 2;
                };
                item object {
                    call center       => object { call sclr => 1.5 };
                    call clip         => 0.75;
                    call dist         => 0;
                    call iter         => 1;
                    call nelem        => 2;
                    call sigma        => 0.5;
                    call total_weight => 2;
                };
                end;
            };
            call nelem        => 2;
            call sigma        => 0.5;
            call success      => 1;
            call total_weight => 2;
        },
        'default result is an object with objects in it',
    );

    isnt( $result->TO_JSON, object {}, q{jsonified top level object isn't an object} );
    isnt(
        $result->TO_JSON->{iterations},
        bag { item object {}; item object {}; },
        q{jsonified lower level objects aren't objects},
    );

    is(
        $result->TO_JSON,
        hash {
            field center     => [1.5];
            field clip       => 0.75;
            field dist       => 0;
            field error      => U();
            field iter       => 1;
            field iterations => array {
                item hash {
                    field center       => [1.5];
                    field clip         => U();
                    field dist         => U();
                    field iter         => 0;
                    field nelem        => 2;
                    field sigma        => 0.5;
                    field total_weight => 2;
                    end;
                };
                item hash {
                    field center       => [1.5];
                    field clip         => 0.75;
                    field dist         => 0;
                    field iter         => 1;
                    field nelem        => 2;
                    field sigma        => 0.5;
                    field total_weight => 2;
                    end;
                };
                end;
            };
            field nelem        => 2;
            field sigma        => 0.5;
            field success      => 1;
            field total_weight => 2;
            end;
        },
        'JSONified result has the correct contents'
    );

};

done_testing;

