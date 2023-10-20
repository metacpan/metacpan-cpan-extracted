#!perl
#
# mostly for code coverage, given that MIDI inspection of some sort
# (eyes, ears) is likely necessary to be really sure that things are
# right for a generator. these tests may also help show what can be
# fiddled around with the objects
#
# MIDI::Event might be good to know, to better understand the MIDI
# structures being returned by the generator classes

use 5.26.0;
use warnings;
use Test2::V0;
#use Data::Dumper;

plan(15);

use Music::Factory;

{
    my $events = [];
    my $gen    = Music::Factory::Generator->new;
    $gen->reset;    # NOTE this may be removed
    my $nope = Music::Factory::AssemblyLine->new(
        events => $events,
        gen    => $gen,
        maxlen => 42,
    );
    like( dies { $nope->update }, qr/need a better implementation/ );
    is( scalar @$events, 0 );
}

# a MIDI "rest" of some duration (another way would be to have some
# state variable of how much dtime to add to the next MIDI event, but
# that's complicated in a different way)
{
    my $events  = [];
    my $silence = Music::Factory::AssemblyLine->new(
        events => $events,
        gen    => Music::Factory::Rest->new,
        maxlen => 96,
    );
    # the return values can however be ignored if you have well behaved
    # generators that do not overflow or do other silly things, or you
    # could always use the returned event list instead of appending to a
    # global $events like my code shows under the eg/ directory
    my ( $epoch, $evlist, $overflow ) = $silence->update;
    is( $epoch,    96 );
    is( $events,   [ [ marker => 96, 'silence' ] ] );
    is( $evlist,   [ [ marker => 96, 'silence' ] ] );
    is( $overflow, undef );
}

# custom update length (what a generator does with this will depend on
# the generator)
{
    my $events  = [];
    my $silence = Music::Factory::AssemblyLine->new(
        events => $events,
        gen    => Music::Factory::Rest->new,
        maxlen => 96,
    );
    my ( $epoch, undef, $overflow ) = $silence->update(1000);
    is( $events,   [ [ marker => 1000, 'silence' ] ] );
    is( $epoch,    1000 );
    is( $overflow, undef );
}

# a MIDI note of some duration
{
    my $events  = [];
    my $silence = Music::Factory::AssemblyLine->new(
        events => $events,
        gen    => Music::Factory::Note->new(
            duration => 96,
            pitch    => sub { 59 },
            velo     => sub { 101 },
        ),
        maxlen => 96,
    );
    my ( $epoch, undef, $overflow ) = $silence->update;
    is( $events,
        [ [ note_on => 0, 0, 59, 101 ], [ note_off => 96, 0, 59, 0 ], ] );
    is( $epoch,    96 );
    is( $overflow, undef );
}

# more MIDI notes, and overflow due to duration/maxlen mismatch. the
# ::Note class has some comments on how to not overflow, if you are
# writing a generator that must not overflow
{
    my $events  = [];
    my $silence = Music::Factory::AssemblyLine->new(
        events => $events,
        gen    => Music::Factory::Note->new(
            duration => 96,
            # are the pitches in the right order?
            pitch => sub { state $p = 59;  $p++ },
            velo  => sub { state $v = 101; $v++ },
        ),
        maxlen => 200,
    );
    my ( $epoch, undef, $overflow ) = $silence->update;
    is( $events,
        [   [ note_on  => 0,  0, 59, 101 ],
            [ note_off => 96, 0, 59, 0 ],
            [ note_on  => 0,  0, 60, 102 ],
            [ note_off => 96, 0, 60, 0 ],
        ]
    );
    is( $epoch, 192 );
    # duration of overflow, and the event(s) involved with said. the
    # caller would then need to figure out what to do, or the generator
    # might be rewritten to do something different
    is( $overflow,
        [
            96, [ [ note_on => 0, 0, 61, 103 ], [ note_off => 96, 0, 61, 0 ], ],
        ]
    );
}
