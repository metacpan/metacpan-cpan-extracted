#!perl
#
# NOTE some of the utility routines do not do much error checking

use 5.24.0;
use Test2::V0;

plan(52);

use MIDI;
use Music::RhythmSet::Util
  qw(beatstring compare_onsets duration filter_pattern flatten ocvec onset_count pattern_from rand_onsets score_fourfour score_stddev upsize write_midi);

my @playback;

my $replay =
  [ [ [qw/1 1 0/], 2 ], [ [qw/1 1 1/], 1 ], [ [qw/0 1/], 3 ] ];

is( beatstring( [qw/1 0 0 1 0 0 1 0 0 0 1 0/] ), 'x..x..x...x.' );
like( dies { beatstring() },     qr/no pattern set/ );
like( dies { beatstring( {} ) }, qr/no pattern set/ );

is( sprintf( '%.0f', compare_onsets( [qw/1 1/], [qw/1 1/] ) ), 1 );
is( sprintf( '%.1f', compare_onsets( [qw/1 1/], [qw/1 0/] ) ), 0.5 );
is( sprintf( '%.0f', compare_onsets( [qw/0 1/], [qw/1 1/] ) ), 1 );
like( dies { compare_onsets( [], [] ) }, qr/no onsets/ );

is( [ duration($replay) ], [ 6, 15 ] );

is( flatten($replay), [qw/1 1 0  1 1 0   1 1 1   0 1  0 1  0 1/] );

is(
    #         0 1 2 3 4 5 6 7 8 9 10
    ocvec( [qw/1 0 0 1 0 0 1 0 0 0 1 0/] ),
    [qw/0 3 6 10/]
);

is( onset_count( [qw/1 0 0 1 0 0 1 0 0 0 1 0/] ), 4 );

# odds are, anyways. downside: slow
is( filter_pattern( 4, 16, 10000 ),
    [ 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0 ] );
ok( lives { filter_pattern( 4, 16, 1000, 0, 1 ) } );

is( pattern_from("x.x."),                     [qw/1 0 1 0/] );
is( pattern_from("blah blah x.x. blah blah"), [qw/1 0 1 0/] );

my ( $on, @slots, $total );
for ( 1 .. 100 ) {
    my $pat = rand_onsets( 5, 10 );
    for my $i ( 0 .. $pat->$#* ) {
        if ( $pat->[$i] == 1 ) {
            $on++;
            $slots[$i]++;
        }
        $total++;
    }
}
# exactly half of the onsets should be turned on
my $half = int( $total / 2 );
is( $on, $half );
# but where the onsets are will hopefully vary and will hopefully be
# evenly divided between the slots. this might also be testing the RNG
my $tolerance = 0.05;
for my $s (@slots) {
    my $vary = abs( $s / $half - 1 / @slots );
    ok( $vary < $tolerance );
}
like( dies { rand_onsets( 1, 1 ) }, qr/onsets must be/ );

is( score_fourfour( [] ),                                    0 );
is( score_fourfour( [qw/1 0 0 0 1 0 0 0 1 0 0 0 1 0 0 0/] ), 512 );

is( score_stddev( [qw/1 0 0 0 1 0 0 0 1 0 0 0 1 0 0 0/] ), 0 );
is( score_stddev( [qw/0 1 0 0 0 1 0 0 0 1 0 0 0 1 0 0/] ), 0 );
# TODO actually check the math on this one but that would probably be
# testing whatever Statistics::Lite is doing and the results seem good
# enough for music (noise) production
is( sprintf( "%.1f", score_stddev( [qw/1 1 1 1 0 0 0 0 0 0 0 0 0 0 0 0/] ) ),
    5.2 );
like( dies { score_stddev( [] ) }, qr/no onsets/ );

is( upsize( [ 1, 0, 1, 1 ], 8 ), [ 1, 0, 0, 0, 1, 0, 1, 0 ] );
like( dies { upsize() }, qr/no pattern set/ );
like( dies { upsize( undef,          99 ) }, qr/no pattern set/ );
like( dies { upsize( [],             99 ) }, qr/no pattern set/ );
like( dies { upsize( {},             99 ) }, qr/no pattern set/ );
like( dies { upsize( [ 1, 1, 1, 1 ], 3 ) },  qr/new length/ );
like( dies { upsize( [ 1, 1, 1, 1 ], 4 ) },  qr/new length/ );

like( dies { duration() },        qr/no replay log/ );
like( dies { duration( {} ) },    qr/no replay log/ );
like( dies { flatten() },         qr/no replay log/ );
like( dies { flatten( {} ) },     qr/no replay log/ );
like( dies { ocvec() },           qr/no pattern set/ );
like( dies { ocvec( {} ) },       qr/no pattern set/ );
like( dies { onset_count() },     qr/no pattern set/ );
like( dies { onset_count( {} ) }, qr/no pattern set/ );

sub domidi {
    my ( $file, $fn ) = @_;
    unlink $file if -f $file;
    $fn->($file);
    # $Test::Builder::Level (see Test2::Manual::Tooling::Nesting)
    my $ctx = context();
    ok( -f $file );
    $ctx->release;
    push @playback, $file;
}

domidi(
    't/refpitch.midi',
    sub {
        my ($file) = @_;
        ok( lives {
                my $track = MIDI::Track->new;
                $track->events( [qw/text_event 0 test/],
                    [qw/note_on 0 0 69 100/], [qw/note_off 288 0 69 0/], );
                write_midi( $file, $track, format => 0, ticks => 96 );
            }
        );
    }
);

# a lot of code to test a little addition to write_midi
domidi(
    't/threetrack.midi',
    sub {
        my ($file) = @_;
        ok( lives {
                my $note = 42;
                my @tracks;
                for my $i ( 1 .. 3 ) {
                    my $track = MIDI::Track->new;
                    $track->events(
                        (   [ 'note_on',  0,        0, $note + 12 * $i, 100 ],
                            [ 'note_off', 288 / $i, 0, $note + 12 * $i, 0 ]
                        ) x $i
                    );
                    push @tracks, $track;
                }
                write_midi( $file, \@tracks );
            }
        );
    }
);

if ( defined $ENV{AUTHOR_TEST_JMATES_MIDI} ) {
    diag "playback ...";
    for my $file (@playback) {
        diag "playing $file ...";
        system $ENV{AUTHOR_TEST_JMATES_MIDI}, $file;
    }
}
