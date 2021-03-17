#!perl
#
# NOTE some of the utility routines do not do much error checking

use 5.24.0;
use Test::Most tests => 52;
my $deeply = \&eq_or_diff;

use MIDI;
use Music::RhythmSet::Util
  qw(beatstring compare_onsets duration filter_pattern flatten ocvec onset_count pattern_from rand_onsets score_fourfour score_stddev upsize write_midi);

my @playback;

my $replay =
  [ [ [qw/1 1 0/], 2 ], [ [qw/1 1 1/], 1 ], [ [qw/0 1/], 3 ] ];

is( beatstring( [qw/1 0 0 1 0 0 1 0 0 0 1 0/] ), 'x..x..x...x.' );
dies_ok { beatstring() };
dies_ok { beatstring( {} ) };

is( sprintf( '%.0f', compare_onsets( [qw/1 1/], [qw/1 1/] ) ), 1 );
is( sprintf( '%.1f', compare_onsets( [qw/1 1/], [qw/1 0/] ) ), 0.5 );
is( sprintf( '%.0f', compare_onsets( [qw/0 1/], [qw/1 1/] ) ), 1 );
dies_ok { compare_onsets( [], [] ) };

$deeply->( [ duration($replay) ], [ 6, 15 ] );

$deeply->( flatten($replay), [qw/1 1 0  1 1 0   1 1 1   0 1  0 1  0 1/] );

$deeply->(
    #         0 1 2 3 4 5 6 7 8 9 10
    ocvec( [qw/1 0 0 1 0 0 1 0 0 0 1 0/] ),
    [qw/0 3 6 10/]
);

is( onset_count( [qw/1 0 0 1 0 0 1 0 0 0 1 0/] ), 4 );

# odds are, anyways. downside: slow
$deeply->(
    filter_pattern( 4, 16, 10000 ),
    [ 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0 ]
);
lives_ok { filter_pattern( 4, 16, 1000, 0, 1 ) };

$deeply->( pattern_from( "x.x." ), [qw/1 0 1 0/] );
$deeply->( pattern_from( "blah blah x.x. blah blah" ), [qw/1 0 1 0/] );

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
dies_ok { rand_onsets( 1, 1 ) };

is( score_fourfour( [] ),                                    0 );
is( score_fourfour( [qw/1 0 0 0 1 0 0 0 1 0 0 0 1 0 0 0/] ), 512 );

is( score_stddev( [qw/1 0 0 0 1 0 0 0 1 0 0 0 1 0 0 0/] ), 0 );
is( score_stddev( [qw/0 1 0 0 0 1 0 0 0 1 0 0 0 1 0 0/] ), 0 );
# TODO actually check the math on this one but that would probably be
# testing whatever Statistics::Lite is doing and the results seem good
# enough for music (noise) production
is( sprintf( "%.1f", score_stddev( [qw/1 1 1 1 0 0 0 0 0 0 0 0 0 0 0 0/] ) ),
    5.2 );
dies_ok { score_stddev( [] ) };

$deeply->( upsize( [ 1, 0, 1, 1 ], 8 ), [ 1, 0, 0, 0, 1, 0, 1, 0 ] );
dies_ok { upsize() } qr/no pattern set/;
dies_ok { upsize( undef,          99 ) } qr/no pattern set/;
dies_ok { upsize( [],             99 ) } qr/no pattern set/;
dies_ok { upsize( {},             99 ) } qr/no pattern set/;
dies_ok { upsize( [ 1, 1, 1, 1 ], 3 ) } qr/new length/;
dies_ok { upsize( [ 1, 1, 1, 1 ], 4 ) } qr/new length/;

dies_ok { duration() };
dies_ok { duration( {} ) };
dies_ok { flatten() };
dies_ok { flatten( {} ) };
dies_ok { ocvec() };
dies_ok { ocvec( {} ) };
dies_ok { onset_count() };
dies_ok { onset_count( {} ) };

sub domidi {
    my ( $file, $fn ) = @_;
    unlink $file if -f $file;
    $fn->($file);
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    ok( -f $file );
    push @playback, $file;
}

domidi(
    't/refpitch.midi',
    sub {
        my ($file) = @_;
        lives_ok {
            my $track = MIDI::Track->new;
            $track->events( [qw/text_event 0 test/],
                [qw/note_on 0 0 69 100/], [qw/note_off 288 0 69 0/], );
            write_midi( $file, $track, format => 0, ticks => 96 );
        };
    }
);

# a lot of code to test a little addition to write_midi
domidi(
    't/threetrack.midi',
    sub {
        my ($file) = @_;
        lives_ok {
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
        };
    }
);

if ( defined $ENV{AUTHOR_TEST_JMATES_MIDI} ) {
    diag "playback ...";
    for my $file (@playback) {
        diag "playing $file ...";
        system $ENV{AUTHOR_TEST_JMATES_MIDI}, $file;
    }
}
