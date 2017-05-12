#!perl

use strict;
use warnings;

use Test::Most;    # plan is down at bottom
my $deeply = \&eq_or_diff;

########################################################################
#
# Fundamentals

use Music::AtonalUtil;

my $atu = Music::AtonalUtil->new;
isa_ok( $atu, 'Music::AtonalUtil' );

is( $atu->scale_degrees, 12, 'expect 12 degrees in scale by default' );

########################################################################
#
# Atonal Foo

{
    my $rtu = Music::AtonalUtil->new;
    $rtu->scale_degrees(16);    # because rhythm

    # Typed up from and compared with graphs in "The Geometry of Musical
    # Rhythm" p.34, p.37.
    $deeply->(
        scalar $rtu->adjacent_interval_content( [ 0, 4, 6, 10, 12 ] ),
        [ 0, 2, 0, 3, 0, 0, 0, 0 ],
        'shiko aic'
    );
    $deeply->(
        scalar $rtu->adjacent_interval_content( [ 0, 3, 6, 10, 12 ] ),
        [ 0, 1, 2, 2, 0, 0, 0, 0 ],
        'son aic'
    );
    $deeply->(
        scalar $rtu->adjacent_interval_content( [ 0, 3, 7, 10, 12 ] ),
        [ 0, 1, 2, 2, 0, 0, 0, 0 ],
        'rumba aic'
    );
    $deeply->(
        scalar $rtu->adjacent_interval_content( [ 0, 3, 6, 10, 11 ] ),
        [ 1, 0, 2, 1, 1, 0, 0, 0 ],
        'soukous aic'
    );
    $deeply->(
        scalar $rtu->adjacent_interval_content( [ 0, 3, 6, 10, 14 ] ),
        [ 0, 1, 2, 2, 0, 0, 0, 0 ],
        'gahu aic'
    );
    $deeply->(
        scalar $rtu->adjacent_interval_content( [ 0, 3, 6, 10, 13 ] ),
        [ 0, 0, 4, 1, 0, 0, 0, 0 ],
        'bossa nova aic'
    );
}

$deeply->( $atu->bits2pcs(137), [ 0, 3, 7 ], 'bits to pitch set' );

$deeply->(
    [ $atu->check_melody( { dup_interval_limit => 3 }, [qw/0 2 4 6/] ) ],
    [ 0, "dup_interval_limit" ],
    'check_melody duplicate intervals'
);

$deeply->(
    [   $atu->check_melody(
            {   exclude_interval => [
                    { iset => [ 5, 5 ], },    # adjacent fourths ("cadential basses")
                ],
            },
            [qw/60 64 57 59 60 57 65 64 62 67 72/]
        )
    ],
    [ 0, "exclude_interval", { index => 8, selection => [ 5, 5 ] } ],
    'check_melody exclude_interval'
);

$deeply->(
    [   $atu->check_melody(
            { exclude_interval => [ { iset => [ 5, 5 ], in => 8 }, ], },
            [qw/0 5 1 1 1 1 1 0 5/]
        )
    ],
    [   0,
        "exclude_interval",
        {   context => [ 5, 4, 0, 0, 0, 0, 1, 5 ],
            index   => 0,
            selection => [ 5, 5 ]
        }
    ],
    'check_melody exclude_interval in wider range'
);

$deeply->(
    [   $atu->check_melody(
            { exclude_interval => [ { iset => [ 1, 3 ], sort => 1 }, ], },
            [qw/0 3 2/]
        )
    ],
    [ 0, "exclude_interval", { index => 0, selection => [ 3, 1 ] } ],
    'check_melody exclude_interval sorting'
);

$deeply->(
    [   $atu->check_melody(
            {   exclude_prime => [
                    { ps => [ 0, 3, 7 ], in => 4 },    # major or minor triad, any guise
                ],
            },
            [qw/4 7 5 0/]
        )
    ],
    [   0,
        "exclude_prime",
        { context => [ 4, 7, 5, 0 ], index => 0, selection => [ 4, 7, 0 ] }
    ],
    'check_melody triad in four notes'
);

$deeply->(
    [   $atu->check_melody(
            {   exclude_prime => [
                    # 7-35 (major/minor scale) but also excluding from all 5-x or
                    # 6-x subsets of said set
                    { ps => [ 0, 1, 3, 5, 6, 8, 10 ], subsets => [ 6, 5 ] },
                ],
            },
            [qw/0 2 4 5 7/]    # c major scale run
        )
    ],
    [ 0, "exclude_prime", { index => 0, selection => [ 0, 2, 4, 5, 7 ] } ],
    'check_melody c major scale run via subsets'
);

$deeply->(
    [   $atu->check_melody(
            {   exclude_half_prime => [
                    { ps => [ 0, 4, 5 ], in => 3 },    # leading tone/tonic/dominant
                ],
            },
            [qw/0 1 5 7 11 12/]
        )
    ],
    [ 0, "exclude_half_prime", { index => 3, selection => [ 7, 11, 12 ] } ],
    'check_melody harmonic cadence'
);

$deeply->(
    $atu->circular_permute( [ 0, 1, 2 ] ),
    [ [ 0, 1, 2 ], [ 1, 2, 0 ], [ 2, 0, 1 ] ],
    'circular permutation'
);

$deeply->(
    $atu->complement( [ 0, 1, 2, 3, 4, 5 ] ),
    [ 6, 7, 8, 9, 10, 11 ],
    'pitch set complement'
);

can_ok( $atu, 'forte_number_re' );
ok( '6-z44' =~ $atu->forte_number_re, 'use forte number regex' );

$deeply->( $atu->forte2pcs('6-Z44'), [ 0, 1, 2, 5, 6, 9 ], 'Forte to PCS1' );
$deeply->( $atu->forte2pcs('6-z44'), [ 0, 1, 2, 5, 6, 9 ], 'Forte to PCS2' );

# normal_form would render these as [9 x 4]; prime_form both as [0,3,7]
$deeply->(
    scalar $atu->half_prime_form(qw/9 0 4/),
    [ 0, 3, 7 ],
    'half_prime_form minor'
);
$deeply->(
    scalar $atu->half_prime_form(qw/9 1 4/),
    [ 0, 4, 7 ],
    'half_prime_form major'
);

$deeply->(
    scalar $atu->interval_class_content( [ 0, 2, 4 ] ),
    [ 0, 2, 0, 1, 0, 0 ],
    'icc icv'
);

$deeply->(
    scalar $atu->interval_class_content(
        [qw/9 0 2 4 6 4 2 11 7 9 11 0 9 8 9 11 8 4/] ),
    [qw/4 6 5 5 6 2/],
    'icc icv of non-unique pitch set'
);

$deeply->(
    $atu->intervals2pcs( 0, [qw/4 3 -1 1 5/] ),
    [qw/0 4 7 6 7 0/], 'intervals2pcs'
);

$deeply->(
    $atu->intervals2pcs( 2, [qw/7 -4 -3/] ),
    [qw/2 9 5 2/], 'intervals2pcs custom start'
);

$deeply->(
    $atu->invariance_matrix( [ 3, 5, 6, 9 ] ),
    [ [ 6, 8, 9, 0 ], [ 8, 10, 11, 2 ], [ 9, 11, 0, 3 ], [ 0, 2, 3, 6 ] ],
    'invariance matrix'
);

$deeply->( $atu->invert( 0, [ 0, 4, 7 ] ), [ 0, 8, 5 ], 'invert something' );

is( $atu->mininterval( 0,  0 ),  0,  "c to c is 0" );
is( $atu->mininterval( 0,  5 ),  5,  "c to f is 5" );
is( $atu->mininterval( 5,  0 ),  -5, "f to c down by 5" );
is( $atu->mininterval( 0,  7 ),  -5, "c g goes down" );
is( $atu->mininterval( 7,  0 ),  5,  "g c goes up" );
is( $atu->mininterval( 0,  11 ), -1, "c to b one down" );
is( $atu->mininterval( 11, 0 ),  1,  "b to c one up" );

$deeply->(
    $atu->multiply( 5, [ 10, 9, 0, 11 ] ),
    [ 2, 9, 0, 7 ],
    'multiply something'
);

$deeply->(
    ( $atu->normal_form( [ 6, 6, 7, 2, 2, 1, 3, 3, 3 ] ) )[0],
    [ 1, 2, 3, 6, 7 ],
    'normal form'
);

$deeply->(
    ( $atu->normal_form( [ 1, 4, 7, 8, 10 ] ) )[0],
    [ 7, 8, 10, 1, 4 ],
    'normal form compactness'
);

$deeply->(
    ( $atu->normal_form( [ 8, 10, 2, 4 ] ) )[0],
    [ 2, 4, 8, 10 ],
    'normal form lowest number fall through'
);

$deeply->(
    (   $atu->normal_form( [ map { my $s = $_ + 24; $s } 6, 6, 7, 2, 2, 1, 3, 3, 3 ] )
    )[0],
    [ 1, 2, 3, 6, 7 ],
    'normal form non-base-register pitches'
);

$deeply->(
    [ $atu->normal_form( 0, 4, 7, 12 ) ],
    [ [ 0, 4, 7 ], { 0 => [ 0, 12 ], 4 => [4], 7 => [7] } ],
    'normal form <c e g c>'
);

is( $atu->pcs2forte( [ 0, 1, 3, 4, 7, 8 ] ), '6-Z19', 'PCS to Forte 1' );
is( $atu->pcs2forte( [qw/6 5 4 1 0 9/] ), '6-Z44', 'PCS to Forte 2' );

is( $atu->pcs2forte( [ 0,  7,  4 ] ),  '3-11', 'PCS to Forte redux 1' );
is( $atu->pcs2forte( [ 4,  1,  8 ] ),  '3-11', 'PCS to Forte redux 2' );
is( $atu->pcs2forte( [ 12, 19, 16 ] ), '3-11', 'PCS to Forte redux 3' );

$deeply->( $atu->pcs2intervals( [qw/0 1 3/] ), [qw/1 2/], 'pcs2intervals' );

is( $atu->pcs2str( [ 0, 3, 7 ] ), "[0,3,7]", 'pcs2str 1' );
is( $atu->pcs2str( 0, 3, 7 ), "[0,3,7]", 'pcs2str 2' );
is( $atu->pcs2str("0,3,7"), "[0,3,7]", 'pcs2str 3' );

is( $atu->pitch2intervalclass(0),  0, 'pitch2intervalclass 0' );
is( $atu->pitch2intervalclass(1),  1, 'pitch2intervalclass 1' );
is( $atu->pitch2intervalclass(11), 1, 'pitch2intervalclass 11' );
is( $atu->pitch2intervalclass(6),  6, 'pitch2intervalclass 6' );

$deeply->(
    $atu->prime_form( [ 9, 10, 11, 2, 3 ] ),
    [ 0, 1, 2, 5, 6 ],
    'prime form'
);

$deeply->(
    $atu->prime_form( [ 21, 22, 23, 14, 15 ] ),
    [ 0, 1, 2, 5, 6 ],
    'prime form should normalize'
);

is( $atu->pcs2bits( [ 0,  3,  7 ] ),  137,  'ps to bits' );
is( $atu->pcs2bits( [ 11, 14, 18 ] ), 2116, 'ps to bits' );

$deeply->( $atu->retrograde( [ 1, 2, 3 ] ), [ 3, 2, 1 ], 'retrograde' );

$deeply->( $atu->rotate( 0, [ 1, 2, 3 ] ), [ 1, 2, 3 ], 'rotate by 0' );

$deeply->( $atu->rotate( 1, [ 1, 2, 3 ] ), [ 3, 1, 2 ], 'rotate by 1' );

$deeply->( $atu->rotate( 2, [ 1, 2, 3 ] ), [ 2, 3, 1 ], 'rotate by 2' );

$deeply->( $atu->rotate( -1, [ 1, 2, 3 ] ), [ 2, 3, 1 ], 'rotate by -1' );

$deeply->(
    $atu->rotateto( 'c', 1, [qw/a b c d e c g/] ),
    [qw/c d e c g a b/], 'rotate to'
);

$deeply->(
    $atu->rotateto( 'c', -1, [qw/a b c d e c g/] ),
    [qw/c g a b c d e/], 'rotate to the other way'
);

# Verified against Musimathics, v.1, p.320.
$deeply->(
    $atu->set_complex( [ 0, 8, 10, 6, 7, 5, 9, 1, 3, 2, 11, 4 ] ),
    [   [ 0,  8,  10, 6,  7,  5,  9,  1,  3,  2,  11, 4 ],
        [ 4,  0,  2,  10, 11, 9,  1,  5,  7,  6,  3,  8 ],
        [ 2,  10, 0,  8,  9,  7,  11, 3,  5,  4,  1,  6 ],
        [ 6,  2,  4,  0,  1,  11, 3,  7,  9,  8,  5,  10 ],
        [ 5,  1,  3,  11, 0,  10, 2,  6,  8,  7,  4,  9 ],
        [ 7,  3,  5,  1,  2,  0,  4,  8,  10, 9,  6,  11 ],
        [ 3,  11, 1,  9,  10, 8,  0,  4,  6,  5,  2,  7 ],
        [ 11, 7,  9,  5,  6,  4,  8,  0,  2,  1,  10, 3 ],
        [ 9,  5,  7,  3,  4,  2,  6,  10, 0,  11, 8,  1 ],
        [ 10, 6,  8,  4,  5,  3,  7,  11, 1,  0,  9,  2 ],
        [ 1,  9,  11, 7,  8,  6,  10, 2,  4,  3,  0,  5 ],
        [ 8,  4,  6,  2,  3,  1,  5,  9,  11, 10, 7,  0 ]
    ],
    'generate set complex'
);

# NOTE normalized with prime_form as do not know whether the output from
# Algorithm::Combinatorics will remain stable
$deeply->(
    [ map $atu->prime_form($_), @{ $atu->subsets( 2, [ 0, 4, 8 ] ) } ],
    [ [ 0, 4 ], [ 0, 4 ], [ 0, 4 ] ], 'subsets1'
);

$deeply->(
    $atu->tcis( [ 10, 9, 0, 11 ] ),
    [ 1, 0, 0, 0, 0, 0, 1, 2, 3, 4, 3, 2 ],
    'transposition inversion common-tone structure (TICS)'
);

$deeply->(
    $atu->tcs( [ 0, 1, 2, 3 ] ),
    [ 4, 3, 2, 1, 0, 0, 0, 0, 0, 1, 2, 3 ],
    'transposition common-tone structure (TCS)'
);

$deeply->(
    $atu->transpose( 3, [ 11, 0, 1, 4, 5 ] ),
    [ 2, 3, 4, 7, 8 ], 'transpose'
);

$deeply->(
    $atu->transpose_invert( 1, 0, [ 10, 9, 0, 11 ] ),
    [ 3, 4, 1, 2 ],
    'transpose_invert'
);

$deeply->(
    $atu->transpose_invert( 1, 6, [ 0, 11, 3 ] ),
    [ 7, 8, 4 ],
    'transpose_invert with axis'
);

$deeply->(
    scalar $atu->variances( [ 3, 5, 6, 9 ], [ 6, 8, 9, 0 ] ),
    [ 6, 9 ],
    'variances - scalar intersection'
);

ok( $atu->zrelation( [ 0, 1, 3, 7 ], [ 0, 1, 4, 6 ] ) == 1, 'z-related yes' );
ok( $atu->zrelation( [ 0, 1, 3 ], [ 0, 3, 7 ] ) == 0, 'z-related no' );

########################################################################
#
# nexti and company, plus other not-really-atonal routines

my @notes = qw/a b c f e/;
ok( $atu->geti( \@notes ) == 0,    'geti' );
ok( $atu->whati( \@notes ) eq 'a', 'whati' );
ok( $atu->nexti( \@notes ) eq 'b', 'nexti' );
$atu->seti( \@notes, 4 );
ok( $atu->nexti( \@notes ) eq 'a', 'nexti' );

$deeply->( [ $atu->lastn( [qw/a b c/] ) ], [qw/b c/], 'lastn default' );
$deeply->( [ $atu->lastn( [qw/a b c/], 99 ) ], [qw/a b c/], 'lastn overflow' );
$atu = Music::AtonalUtil->new( lastn => 3 );
$deeply->( [ $atu->lastn( [qw/a b c/] ) ], [qw/a b c/], 'lastn custom n' );

{
    my @pitches  = -10 .. 10;
    my @expected = qw/2 3 4 5 4 3 2 3 4 5 4 3 2 3 4 5 4 3 2 3 4/;
    my @results;
    for my $p (@pitches) {
        push @results, $atu->reflect_pitch( $p, 2, 5 );
    }
    $deeply->( \@results, \@expected, 'reflect_pitch' );
}

########################################################################
#
# Other Tests

$atu->scale_degrees(3);
is( $atu->scale_degrees, 3, 'custom number of scale degrees' );

is( $atu->pitch2intervalclass(0), 0, 'pitch2intervalclass (dis3) 0' );
is( $atu->pitch2intervalclass(1), 1, 'pitch2intervalclass (dis3) 1' );
is( $atu->pitch2intervalclass(2), 1, 'pitch2intervalclass (dis3) 2' );

# Custom constructor
my $stu = Music::AtonalUtil->new( DEG_IN_SCALE => 17 );
isa_ok( $stu, 'Music::AtonalUtil' );

is( $stu->scale_degrees, 17, 'custom number of scale degrees' );

# waste of CPU, (low) risk of blow-uppage
#my $melody = Music::AtonalUtil->new->gen_melody;
#diag("melody for this test is: @$melody");

plan tests => 91;
