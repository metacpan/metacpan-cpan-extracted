#!/usr/bin/env perl
use strict;
use warnings;

use Data::Dumper::Compact qw(ddc);
use Getopt::Long qw(GetOptions);
use MIDI::Util qw(setup_score midi_format play_fluidsynth);
use Music::Dice ();

my %opt = (
    tonic     => 'C',
    scale     => 'major',
    octave    => 5,
    patch     => 0,
    bpm       => 90,
    soundfont => $ENV{HOME} . '/Music/soundfont/FluidR3_GM.sf2',
    midi_file => "$0.mid",
);
GetOptions(\%opt,
    'tonic=s',
    'scale=s',
    'octave=i',
    'patch=i',
    'bpm=i',
    'soundfont=s',
    'midi_file=s',
);

my $d = Music::Dice->new(
    scale_note => $opt{tonic},
    scale_name => $opt{scale},
);

my $score = setup_score(
    patch => $opt{patch},
    bpm   => $opt{bpm},
);

my $phrase = $d->rhythmic_phrase->roll;
print 'Rolled phrase: ', ddc($phrase);

for (1 .. 4) {
    my @notes;
    for my $i (0 .. $#$phrase) {
        my $note = $d->note->roll;
        $score->n($phrase->[$i], midi_format($note));
        push @notes, $note;
    }
    print 'Rolled notes: ', ddc(\@notes);
}

# $score->write_score($opt{midi_file});
play_fluidsynth($score, $opt{midi_file}, $opt{soundfont});
