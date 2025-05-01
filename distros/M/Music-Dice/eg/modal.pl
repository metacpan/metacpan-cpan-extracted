#!/usr/bin/env perl
use strict;
use warnings;

use Data::Dumper::Compact qw(ddc);
use Getopt::Long qw(GetOptions);
use MIDI::Util qw(setup_score midi_format play_fluidsynth);
use Music::Chord::Note ();
use Music::Dice ();
use Music::Scales qw(get_scale_notes);

my %opt = (
    tonic     => 'C',
    scale     => 'major',
    octave    => 4,
    bpm       => 80,
    patch     => 0,
    soundfont => $ENV{HOME} . '/Music/soundfont/FluidR3_GM.sf2',
    midi_file => "$0.mid",
);
GetOptions(\%opt,
    'tonic=s',
    'scale=s',
    'octave=i',
    'bpm=i',
    'patch=i',
    'soundfont=s',
    'midi_file=s',
);

my $score = setup_score(
    patch => $opt{patch},
    bpm   => $opt{bpm},
);

my $cn = Music::Chord::Note->new;

my $d = Music::Dice->new(
    scale_note => $opt{tonic},
    scale_name => $opt{scale},
);

my $phrase = $d->rhythmic_phrase->roll;
my $tonic  = $d->note->roll;
my $mode   = $d->mode->roll;
my @scale  = get_scale_notes($tonic, $mode);
print "$tonic $mode: @scale\n";
print "degree => chord | duruation\n";

$d = Music::Dice->new(
    scale_note => $tonic,
    scale_name => $mode,
);

for (1 .. 4) {
    for my $i (0 .. $#$phrase) {
        my ($degree, $triad) = $d->mode_degree_triad_roll($mode);
        my $index = $degree - 1;
        my $type = $triad eq 'diminished' ? 'dim' : $triad eq 'minor' ? 'm' : '';
        my $chord = "$scale[$index]$type";
        print "$degree => $chord | $phrase->[$i]\n";
        my @tones = $cn->chord_with_octave($chord, $opt{octave});
        $score->n($phrase->[$i], midi_format(@tones))
    }
}

# $score->write_score($opt{midi_file});
play_fluidsynth($score, $opt{midi_file}, $opt{soundfont});
