#!/usr/bin/env perl
use strict;
use warnings;

use Data::Dumper::Compact qw(ddc);
use List::Util qw(uniq);
use MIDI::Util qw(setup_score midi_format play_fluidsynth);
use Music::Dice ();
use Term::Choose ();

my $max     = 4; # maximum number of chords
my $loop    = 2; # number of times to play the chord progression
my $choices = [1 .. 4]; # number of notes to play

my @chords;

my $d = Music::Dice->new(
    scale_note => 'C',
    scale_name => 'major',
);

for my $i (1 .. $max) {
    my $prompt = "How many notes in chord $i?";
    my $tc = Term::Choose->new({ prompt => $prompt });
    my $n = $tc->choose($choices);

    my @notes;
    for my $i (1 .. $n) {
        my $note = $d->note->roll;
        push @notes, $note;
    }
    @notes = uniq(@notes);
    print ddc(\@notes);
    push @chords, \@notes;
}

my $score = setup_score(
    patch => 4,
    bpm   => 100,
);

for (1 .. $loop) {
    $score->n('dhn', midi_format(@$_)) for @chords;
    $score->r('qn');
}

play_fluidsynth($score, "$0.mid", $ENV{HOME} . '/Music/soundfont/FluidR3_GM.sf2');
