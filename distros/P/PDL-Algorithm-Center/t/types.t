#! perl

use Test2::V0;
use Test2::API qw[ context ];
use PDL::Lite;
use PDL::Algorithm::Center::Types -all;

my $null = PDL->null;
my $d0   = PDL->new( 1 );
my $d1   = PDL->new( [1] );
my $d1E  = PDL->new( [] );
my $d2   = PDL->new( [1], [1] );
my $d2E  = PDL->new( [], [] );

my $d1_1 = PDL->new( [1] );
my $d2_1 = PDL->new( [ [1] ] );

sub _cmp_pdl {
    my ( $p1, $p2 ) = @_;

    return PDL::all( $p1->shape == $p2->shape ) && PDL::all( $p1 == $p2 );
}

sub coerce_lives {

    my ( $c, $input, $exp, $label ) = @_;

    my $ctx = context();

    my $got;

    my $ok
      = $ctx->ok( lives { $got = $c->assert_coerce( $input ) }, "$label: coerce" )->pass
      ? $ctx->ok( _cmp_pdl( $got, $exp ), "$label: value" )->pass
          ? 1
          : do { note $got; 0 }
      : do { note $@; 0 };

    $ctx->release;

    return $ok;
}

sub coerce_dies {

    my ( $c, $input, $label ) = @_;

    my $ctx = context();

    my $got;

    my $ok
      = $ctx->ok( dies { $got = $c->assert_coerce( $input ) }, $label )->pass
      ? 1
      : do { note $got; 0; };

    $ctx->release;

    return $ok;
}

subtest 'Piddle0D_ne' => sub {

    my $t = Piddle0D_ne;

    # 0D piddles can't be empty, so can't check it
    subtest "check" => sub {
        ok( !$t->check( $null ), 'null' );
        ok( $t->check( $d0 ),    '0D' );
        ok( !$t->check( $d1 ),   '1D' );
        ok( !$t->check( $d1E ),  '1DE' );
        ok( !$t->check( $d2 ),   '2D' );
        ok( !$t->check( $d2E ),  '2DE' );
    };


    subtest "coerce" => sub {

        coerce_lives( $t, 1,   $d0, 'number' );
        coerce_lives( $t, $d0, $d0, '0D' );

        coerce_dies( $t, 'foo', 'scalar' );
        coerce_dies( $t, [3], '[number]' );
        coerce_dies( $t, {}, 'hash' );

    };

};

subtest 'Piddle1D_ne' => sub {

    my $t = Piddle1D_ne;

    subtest 'check' => sub {
        ok( !$t->check( $null ), ' null ' );
        ok( !$t->check( $d0 ),   ' 0D ' );
        ok( $t->check( $d1 ),    ' 1D ' );
        ok( !$t->check( $d1E ),  ' 1DE ' );
        ok( !$t->check( $d2 ),   ' 2D ' );
        ok( !$t->check( $d2E ),  ' 2DE ' );

    };

    subtest "coerce" => sub {

        coerce_lives( $t, 1,   $d1, 'number' );
        coerce_lives( $t, $d0, $d1, '0D value' );
        coerce_lives( $t, [1], $d1, '[number]' );
        coerce_lives( $t, $d1, $d1, '1D' );

        coerce_dies( $t, $d2,   '2D' );
        coerce_dies( $t, 'foo', 'scalar' );
        coerce_dies( $t, {}, 'hash' );

    };

};

subtest 'Piddle2D_ne' => sub {

    my $t = Piddle2D_ne;

    subtest 'check' => sub {

        ok( !$t->check( $null ), 'null' );
        ok( !$t->check( $d0 ),   '0D' );
        ok( !$t->check( $d1 ),   '1D' );
        ok( !$t->check( $d1E ),  '1DE' );
        ok( $t->check( $d2 ),    '2D' );
        ok( !$t->check( $d2E ),  '2DE' );
    };

    subtest "coerce" => sub {

        coerce_lives( $t, 1,   $d2_1, 'number' );
        coerce_lives( $t, $d0, $d2_1, '0D' );
        coerce_lives( $t, [1],     $d2_1, '[number]' );
        coerce_lives( $t, [ [1] ], $d2_1, '[ [number] ]' );
        coerce_lives( $t, $d1, $d2_1, '1D' );
        coerce_lives( $t, $d2, $d2,   '2D' );

        coerce_dies( $t, 'foo', 'scalar' );
        coerce_dies( $t, {}, 'hash' );
    };
};

subtest 'Piddle_min1D_ne' => sub {

    my $t = Piddle_min1D_ne;

    subtest 'check' => sub {

        ok( !$t->check( $null ), 'null' );
        ok( !$t->check( $d0 ),   '0D' );
        ok(  $t->check( $d1 ),   '1D' );
        ok( !$t->check( $d1E ),  '1DE' );
        ok(  $t->check( $d2 ),    '2D' );
        ok( !$t->check( $d2E ),  '2DE' );
    };

    subtest "coerce" => sub {

        coerce_lives( $t, 1,   $d1_1, 'number' );
        coerce_lives( $t, $d0, $d1_1, '0D' );
        coerce_lives( $t, [1],     $d1_1, '[number]' );
        coerce_lives( $t, [ [1] ], $d1_1, '[ [number] ]' );
        coerce_lives( $t, $d1, $d1_1, '1D' );
        coerce_lives( $t, $d2, $d2,   '2D' );

        coerce_dies( $t, 'foo', 'scalar' );
        coerce_dies( $t, {}, 'hash' );
    };
};

subtest 'Piddle1DFromPiddle0D' => sub {

    my $c = Piddle1DFromPiddle0D;

    my $r;

    coerce_lives( $c, 1,   $d1, 'number' );
    coerce_lives( $c, $d0, $d1, '0D' );
    coerce_lives( $c, $d1, $d1, '1D' );

    coerce_dies( $c, $d2,   '2D' );
    coerce_dies( $c, 'foo', 'scalar' );
    coerce_dies( $c, {}, 'hash' );

};

subtest 'Piddle2DFromPiddle1D' => sub {

    my $c = Piddle2DFromPiddle1D;

    coerce_lives( $c, 1,   $d2_1, 'number' );
    coerce_lives( $c, $d0, $d2_1, '0D' );
    coerce_lives( $c, [1], $d2_1, '[number]' );
    coerce_lives( $c, $d1, $d2_1, '1D' );
    coerce_lives( $c, $d2, $d2,   '2D' );

    coerce_dies( $c, 'foo', 'scalar' );
    coerce_dies( $c, {}, 'hash' );

};

subtest 'Piddle2DFromArrayOfPiddle1D' => sub {

    my $c = Piddle2DFromArrayOfPiddle1D;

    coerce_dies( $c, PDL->null, 'null' );
    coerce_dies( $c, 3,         'number' );

    coerce_lives( $c, [1], $d2_1, '[number]' );
    coerce_lives(
        $c,
        [ [ 2, 3 ], [ 4, 5 ] ],
        PDL->new( [ [ 2, 4 ], [ 3, 5 ] ] ),
        '[ [ number ], [number] ]'
    );

};

subtest 'Coords' => sub {

    my $t = Coords;

    # 0D piddles can't be empty, so can't check it
    subtest "check" => sub {
        ok( !$t->check( $null ), 'null' );
        ok( !$t->check( $d0 ),   '0D' );
        ok( !$t->check( $d1 ),   '1D' );
        ok( !$t->check( $d1E ),  '1DE' );
        ok( $t->check( $d2 ),    '2D' );
        ok( !$t->check( $d2E ),  '2DE' );
    };


    subtest "coerce" => sub {

        coerce_lives( $t, 1,   $d1, 'number' );
        coerce_lives( $t, $d0, $d1, '0D' );
        coerce_lives( $t, [1], $d1, '[number]' );
        coerce_lives( $t, $d1, $d1, '1D' );
        coerce_lives( $t, $d2, $d2, '2D' );

        coerce_lives(
            $t,
            [ [ 2, 3 ], [ 4, 5 ] ],
            PDL->new( [ [ 2, 4 ], [ 3, 5 ] ] ),
            '[ [ number ], [number] ]'
        );

        coerce_dies( $t, 'foo', 'scalar' );
        coerce_dies( $t, {}, 'hash' );

    };
};

subtest 'Center' => sub {

    my $t = Center;

    # 0D piddles can't be empty, so can't check it
    subtest "check" => sub {
        ok( !$t->check( $null ), 'null' );
        ok( !$t->check( $d0 ),   '0D' );
        ok( $t->check( $d1 ),   '1D' );
        ok( !$t->check( $d1E ),  '1DE' );
        ok( !$t->check( $d2 ),    '2D' );
        ok( !$t->check( $d2E ),  '2DE' );
    };


    subtest "coerce" => sub {

        coerce_lives( $t, 1,   $d1, 'number' );
        coerce_lives( $t, $d0, $d1, '0D' );
        coerce_lives( $t, [1], $d1, '[number]' );
        coerce_lives( $t, $d1, $d1, '1D' );

        coerce_lives( $t, [ 1, 2 ], PDL->new( 1, 2 ), '[number, number]' );

        coerce_dies( $t, $d2, '2D' );
        coerce_dies( $t, 'foo', 'scalar' );
        coerce_dies( $t, {}, 'hash' );

    };
};

done_testing
