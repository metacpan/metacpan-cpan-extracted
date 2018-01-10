#!perl

use strict;
use warnings;


use Test2::V0;
use Test2::Tools::Compare qw[ object call ];
use Number::Tolerant;

use PDL::Algorithm::Center qw[ sigma_clip ];

use PDL;
use PDL::GSL::RNG;

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

########################################
# interface

my %req = ( nsigma => 1.5, dtol => 1.0 );

# coordinates
subtest "coords" => sub {

    my $e;

    isa_ok( $e = dies { sigma_clip( %req, coords => PDL->null ) },
        [ eclass( 'parameter' ) ], 'null' );

    isa_ok( $e = dies { sigma_clip( %req, coords => PDL->zeroes( 0 ) ) },
        [ eclass( 'parameter' ) ], 'empty' );

    isa_ok( $e = dies { sigma_clip( %req, coords => 'scalar' ) },
        [ eclass( 'parameter' ) ], 'scalar' );

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

    ok(
        lives { sigma_clip( %req, coords => [ pdl( 1, 2 ) ] ) },
        "[ pdl(1, 2) ]",
    ) or note( $@ );

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
                center => [ 1.5 ],
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

    isa_ok(
        dies { sigma_clip( %req, ) },
        [ eclass( 'parameter' ) ],
        'neither coords nor weight'
    );

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

sub _generate_sample {

    my %attr;

    # so tests are reproducible
    my $rng = PDL::GSL::RNG->new( 'taus' );
    $rng->set_seed( 1 );
    srand( 1 );

    $attr{nelem} = 100000;

    # generate a bunch of coordinates
    $attr{coords} = $rng->ran_bivariate_gaussian( 10, 8, 0.5, $attr{nelem} );
    $attr{initial_center} = pdl( 0.5, 0.5 );
    $attr{average_center} = $attr{coords}->xchg(0,1)->average->unpdl;

    # calculate sigma for those inside of a radius of 10
    $attr{mask} = dsumover( ( $attr{coords} - $attr{initial_center} )**2 ) < 100;
    $attr{inside} = $attr{coords}->xchg( 0, 1 )->whereND( $attr{mask} )->xchg( 0, 1 );

    $attr{ninside} = $attr{inside}->dim( 1 );
    $attr{sigma} = tolerance( sqrt( dsum( ( $attr{inside} - $attr{initial_center} )**2 ) / $attr{ninside} ), plus_or_minus => .00000001 );

    $attr{center} = [ tolerance( 0.0126755884280886, plus_or_minus => 0.001 ),
                   tolerance( 0.0337090322699186, plus_or_minus => 0.001 ),
                   ];

    $attr{dist} = tolerance( 0, plus_or_minus => 0.001 );

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
    my @exp_center = @{ $sample->average_center };
    $iter0->center( $iter0->center->unpdl );
    $iter0->{center_0} = $iter0->center->[0];
    $iter0->{center_1} = $iter0->center->[1];
    is(
        $iter0,
        object {
            call nelem => $sample->nelem;
            call total_weight => $sample->nelem;
            call center_0 => validator( '==', $exp_center[0] => sub { $_ ==  $exp_center[0] } );
            call center_1 => validator( '==', $exp_center[1] => sub { $_ ==  $exp_center[1] } );
            end();
        },
        "iteration 0",
    );

    # ensure  the last one agrees with previous fiducial runs, to see
    # if something has broken

    # Test2::V0 can't handle objects which overload &&.
    $results->center( $results->center->unpdl );
    $results->{center_0} = $results->center->[0];
    $results->{center_1} = $results->center->[1];
    #<<< notidy
    is(
        $results,
        object {
            call iter => 70;
            call dist => validator( '==', $sample->dist => sub { $_ == $sample->dist } );
            call nelem => 43597;
            call total_weight => 43597;
            call center_0 => validator( '==', $sample->center->[0] => sub { $_ ==  $sample->center->[0] } );
            call center_1 => validator( '==', $sample->center->[1] => sub { $_ ==  $sample->center->[1] } );
            end(),
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
    my @exp_center =$sample->initial_center->list;
    $iter0->center( $iter0->center->unpdl );
    $iter0->{center_0} = $iter0->center->[0];
    $iter0->{center_1} = $iter0->center->[1];
    is(
        $iter0,
        object {
            call nelem => $sample->nelem;
            call total_weight => $sample->nelem;
            call center_0 => validator( '==', $exp_center[0] => sub { $_ ==  $exp_center[0] } );
            call center_1 => validator( '==', $exp_center[1] => sub { $_ ==  $exp_center[1] } );
            end();
        },
        "iteration 0",
    );

    # ensure  the last one agrees with previous fiducial runs, to see
    # if something has broken

    # Test2::V0 can't handle objects which overload &&.
    $results->center( $results->center->unpdl );
    $results->{center_0} = $results->center->[0];
    $results->{center_1} = $results->center->[1];
    #<<< notidy
    is(
        $results,
        object {
            call iter => 70;
            call dist => validator( '==', $sample->dist => sub { $_ == $sample->dist } );
            call nelem => 43597;
            call total_weight => 43597;
            call center_0 => validator( '==', $sample->center->[0] => sub { $_ ==  $sample->center->[0] } );
            call center_1 => validator( '==', $sample->center->[1] => sub { $_ ==  $sample->center->[1] } );
            end(),
        },
        "iteration -1",
    );
    #>>> notidy
};

subtest 'coords, no clip, initial center = [ X, undef]' => sub {

    my $sample = _generate_sample();

    my $results = sigma_clip(
        center => [ $sample->initial_center->at(0), undef ],
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
    my @exp_center =( $sample->initial_center->at(0), $sample->average_center->[1] );
    $iter0->center( $iter0->center->unpdl );
    $iter0->{center_0} = $iter0->center->[0];
    $iter0->{center_1} = $iter0->center->[1];
    is(
        $iter0,
        object {
            call nelem => $sample->nelem;
            call total_weight => $sample->nelem;
            call center_0 => validator( '==', $exp_center[0] => sub { $_ ==  $exp_center[0] } );
            call center_1 => validator( '==', $exp_center[1] => sub { $_ ==  $exp_center[1] } );
            end();
        },
        "iteration 0",
    );

    # ensure  the last one agrees with previous fiducial runs, to see
    # if something has broken

    # Test2::V0 can't handle objects which overload &&.
    $results->center( $results->center->unpdl );
    $results->{center_0} = $results->center->[0];
    $results->{center_1} = $results->center->[1];
    #<<< notidy
    is(
        $results,
        object {
            call iter => 70;
            call dist => validator( '==', $sample->dist => sub { $_ == $sample->dist } );
            call nelem => 43597;
            call total_weight => 43597;
            call center_0 => validator( '==', $sample->center->[0] => sub { $_ ==  $sample->center->[0] } );
            call center_1 => validator( '==', $sample->center->[1] => sub { $_ ==  $sample->center->[1] } );
            end(),
        },
        "iteration -1",
    );
    #>>> notidy
};

subtest 'coords, no clip, initial center => [undef,Y]' => sub {

    my $sample = _generate_sample();

    my $results = sigma_clip(
        center => [ undef, $sample->initial_center->at(1) ],
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
    my @exp_center =( $sample->average_center->[0], $sample->initial_center->at(1) );
    $iter0->center( $iter0->center->unpdl );
    $iter0->{center_0} = $iter0->center->[0];
    $iter0->{center_1} = $iter0->center->[1];
    is(
        $iter0,
        object {
            call nelem => $sample->nelem;
            call total_weight => $sample->nelem;
            call center_0 => validator( '==', $exp_center[0] => sub { $_ ==  $exp_center[0] } );
            call center_1 => validator( '==', $exp_center[1] => sub { $_ ==  $exp_center[1] } );
            end();
        },
        "iteration 0",
    );

    # ensure  the last one agrees with previous fiducial runs, to see
    # if something has broken

    # Test2::V0 can't handle objects which overload &&.
    $results->center( $results->center->unpdl );
    $results->{center_0} = $results->center->[0];
    $results->{center_1} = $results->center->[1];
    #<<< notidy
    is(
        $results,
        object {
            call iter => 70;
            call dist => validator( '==', $sample->dist => sub { $_ == $sample->dist } );
            call nelem => 43597;
            call total_weight => 43597;
            call center_0 => validator( '==', $sample->center->[0] => sub { $_ ==  $sample->center->[0] } );
            call center_1 => validator( '==', $sample->center->[1] => sub { $_ ==  $sample->center->[1] } );
            end(),
        },
        "iteration -1",
    );
    #>>> notidy
};

subtest 'coords, no clip, initial center => [undef, undef]' => sub {

    my $sample = _generate_sample();

    my $results = sigma_clip(
        center => [ undef, undef ],
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
    my @exp_center =@{ $sample->average_center };
    $iter0->center( $iter0->center->unpdl );
    $iter0->{center_0} = $iter0->center->[0];
    $iter0->{center_1} = $iter0->center->[1];
    is(
        $iter0,
        object {
            call nelem => $sample->nelem;
            call total_weight => $sample->nelem;
            call center_0 => validator( '==', $exp_center[0] => sub { $_ ==  $exp_center[0] } );
            call center_1 => validator( '==', $exp_center[1] => sub { $_ ==  $exp_center[1] } );
            end();
        },
        "iteration 0",
    );

    # ensure  the last one agrees with previous fiducial runs, to see
    # if something has broken

    # Test2::V0 can't handle objects which overload &&.
    $results->center( $results->center->unpdl );
    $results->{center_0} = $results->center->[0];
    $results->{center_1} = $results->center->[1];
    #<<< notidy
    is(
        $results,
        object {
            call iter => 70;
            call dist => validator( '==', $sample->dist => sub { $_ == $sample->dist } );
            call nelem => 43597;
            call total_weight => 43597;
            call center_0 => validator( '==', $sample->center->[0] => sub { $_ ==  $sample->center->[0] } );
            call center_1 => validator( '==', $sample->center->[1] => sub { $_ ==  $sample->center->[1] } );
            end(),
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
            call sigma => validator( '==', $sample->sigma, sub { $_ == $sample->sigma } );
            call nelem => $sample->ninside;
            call total_weight => $sample->ninside;
            end();
        },
        "iteration 0",
    );

    # and that the last one agrees with previous fiducial runs, to see
    # if something has broken

    # Test2::V0 can't handle objects which overload &&.
    $results->center( $results->center->unpdl );
    $results->{center_0} = $results->center->[0];
    $results->{center_1} = $results->center->[1];
    #<<< notidy
    is(
        $results,
        object {
            call iter => 56;
            call dist => validator( '==', $sample->dist => sub { $_ == $sample->dist } );
            call nelem => 43597;
            call total_weight => 43597;
            call center_0 => validator( '==', $sample->center->[0] => sub { $_ ==  $sample->center->[0] } );
            call center_1 => validator( '==', $sample->center->[1] => sub { $_ ==  $sample->center->[1] } );
            end(),
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
           call sigma  => validator( '==', $sample->sigma, sub { $_ == $sample->sigma } );
           call nelem => $sample->ninside;
           call total_weight => $sample->ninside;
       },
       "iteration 0",
      );

    # Test2::V0 can't handle objects which overload &&.
    $results->center( $results->center->unpdl );
    $results->{center_0} = $results->center->[0];
    $results->{center_1} = $results->center->[1];
    #<<< notidy
    is(
        $results,
        object {
            call iter => 56;
            call dist => validator( '==', $sample->dist => sub { $_ == $sample->dist } );
            call nelem => 43597;
            call total_weight => 43597;
            call center_0 => validator( '==', $sample->center->[0] => sub { $_ ==  $sample->center->[0] } );
            call center_1 => validator( '==', $sample->center->[1] => sub { $_ ==  $sample->center->[1] } );
            end(),
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
    my $inside_weight_sum = $inside_weight->dsum;

    $sample->sigma( sqrt( dsum( $inside_weight * dsumover( ( $sample->inside - $sample->initial_center )**2 ) ) / $inside_weight_sum ) );

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
           call sigma  => validator( '==', $sample->sigma, sub { $_ == $sample->sigma } );
           call nelem => $sample->ninside;
           call total_weight => $inside_weight_sum;
       },
       "iteration 0",
      );


    # Test2::V0 can't handle objects which overload &&.
    $results->center( $results->center->unpdl );
    $results->{center_0} = $results->center->[0];
    $results->{center_1} = $results->center->[1];
    #<<< notidy
    is(
        $results,
        object {
            call iter => 56;
            call dist => validator( '==', $sample->dist => sub { $_ == $sample->dist } );
            call nelem => 43597;
            call total_weight => 43597 * 2;
            call center_0 => validator( '==', $sample->center->[0] => sub { $_ ==  $sample->center->[0] } );
            call center_1 => validator( '==', $sample->center->[1] => sub { $_ ==  $sample->center->[1] } );
            end(),
        },
        "iteration -1",
    );
    #>>> notidy


};


done_testing;

