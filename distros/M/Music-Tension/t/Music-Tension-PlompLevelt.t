#!perl

use strict;
use warnings;
use Test::Most tests => 30;
my $deeply = \&eq_or_diff;

use Music::Tension::PlompLevelt;
my $tension = Music::Tension::PlompLevelt->new;

is( sprintf( "%.03f", $tension->frequencies( 440, 440 ) ),
    0.017, 'tension of frequency at unison' );
is( sprintf( "%.03f", $tension->frequencies( 440, 440 * 2 ) ),
    0.022, 'tension of frequency at octave' );
is( sprintf( "%.03f", $tension->frequencies( 440, 440 * 3 / 2 ) ),
    0.489, 'tension of frequency at perfect fifth' );
is( sprintf( "%.03f", $tension->frequencies( 440, 440 * 9 / 8 ) ),
    1.752, 'tension of frequency at greater tone (major 2nd)' );

dies_ok { $tension->frequencies(440) } qr/frequency2/;
dies_ok { $tension->frequencies( undef, 440 ) } qr/frequency1/;

# not sure why I added this input method, but maybe someone is using it
# so dunna want to remove it...
is( sprintf(
        "%.03f",
        $tension->frequencies(
            [   { amp => 1, freq => 440 },
                {   amp  => "2.9",
                    freq => 880
                },
                {   amp  => "3.6",
                    freq => 1320
                },
                { amp => "2.6", freq => 1760 },
                { amp => "1.1", freq => 2200 },
                {   amp  => "0.2",
                    freq => 2640
                }
            ],
            [   { amp => 1, freq => 440 },
                {   amp  => "2.9",
                    freq => 880
                },
                { amp => "3.6", freq => 1320 },
                { amp => "2.6", freq => 1760 },
                {   amp  => "1.1",
                    freq => 2200
                },
                { amp => "0.2", freq => 2640 }
            ]
        )
    ),
    0.017,
    'tension of frequency at unison II'
);
dies_ok { $tension->frequencies( [],     440 ) } qr/frequency1/;
dies_ok { $tension->frequencies( 440,    [] ) } qr/frequency2/;
dies_ok { $tension->frequencies( {},     440 ) } qr/frequency1/;
dies_ok { $tension->frequencies( 440,    {} ) } qr/frequency2/;
dies_ok { $tension->frequencies( ["xa"], 440 ) } qr/frequency1/;
dies_ok { $tension->frequencies( 440,    ["xa"] ) } qr/frequency2/;

# equal temperament has higher tension, excepting unison/octaves
is( sprintf( "%.03f", $tension->pitches( 69, 69 ) ),
    0.017, 'tension of pitches at unison' );

dies_ok { $tension->pitches } qr/two pitches/;
dies_ok { $tension->pitches(440) } qr/two pitches/;
dies_ok { $tension->pitches( 440,  "xa" ) } qr/positive/;
dies_ok { $tension->pitches( "xa", 440 ) } qr/positive/;

is( sprintf( "%.01f", scalar $tension->vertical( [qw/60 64 67/] ) ),
    3.6, 'tension of major triad (equal temperament)' );

my @ret = $tension->vertical( [qw/60 67 64/] );
is( scalar @ret,          4 );
is( scalar @{ $ret[-1] }, 2 );

dies_ok { $tension->vertical } qr/array ref/;
dies_ok { $tension->vertical( {} ) } qr/array ref/;
dies_ok { $tension->vertical( [] ) } qr/multiple/;

if ( $ENV{AUTHOR_TEST_JMATES} ) {
    $tension = Music::Tension::PlompLevelt->new( normalize_amps => 1 );

    # Just Intonation, Major (minor is 1 9/8 6/5 4/3 3/2 8/5 9/5), in
    # what should be least to most dissonant but the code is broken
    # right now so
    # TODO figure out what is broken...
    my @just_ratios = ( 1, 2, 3 / 2, 5 / 3, 4 / 3, 5 / 4, 15 / 8, 9 / 8 );

    diag "DBG some numbers to puzzle over";
    my $base_freq = 440;
    for my $r (@just_ratios) {
        diag sprintf "DBG freq %d:%d\t%.06f", $base_freq, $base_freq * $r,
          $tension->frequencies( $base_freq, $base_freq * $r );
    }
    # $base_freq = 440;
    # for my $f ($base_freq..$base_freq*3) {
    #   diag sprintf "FOR_R freq %d %d %.06f", $base_freq, $f,
    #     $tension->frequencies( $base_freq, $f );
    # }

    undef $tension;
}

########################################################################
#
# new() params

my $mtc = Music::Tension::PlompLevelt->new(
    amplitudes          => { zeros => [qw/0 0 0/] },
    default_amp_profile => 'zeros',
    reference_frequency => 640,
);

dies_ok { Music::Tension::PlompLevelt->new( amplitudes => { zeros => undef } ) };
dies_ok { Music::Tension::PlompLevelt->new( amplitudes => { zeros => {} } ) };

dies_ok {
    Music::Tension::PlompLevelt->new(
        default_amp_profile => "THIS MUST NOT EXIST BECAUSE TESTING" )
};

{
    my $tension = Music::Tension::PlompLevelt->new(
        amplitudes     => { test => [ 1 .. 4 ] },
        normalize_amps => 1
    );
    # TODO convert it to Moo and make these attributes, but that's
    # more work
    my @amps = map { sprintf "%.1f", $_ } @{ $tension->{_amplitudes}{test} };
    $deeply->( \@amps, [ "0.1", "0.2", "0.3", "0.4" ] );
}

is( $mtc->frequencies( 440, 495 ), 0, 'zero times anything is zero tension' );

# inherited from parent class
is( $mtc->pitch2freq(69), 640, 'pitch 69 to frequency, ref pitch 640' );
