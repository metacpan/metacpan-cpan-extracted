#!/usr/bin/env perl
use strict;
use warnings;

use Getopt::Long qw(GetOptions);
use MIDI::Util qw(setup_score midi_format);
use Music::Dice ();

my %opt = (
    tonic  => 'C',
    scale  => 'major',
    octave => 5,
);
GetOptions(\%opt,
    'tonic=s',
    'scale=s',
    'octave=i',
);

my $d = Music::Dice->new(
    scale_note => $opt{tonic},
    scale_name => $opt{scale},
);

my $score = setup_score(patch => 0, bpm => 80);

my $phrase = $d->rhythmic_phrase->roll;

for (1 .. 4) {
    for my $i (0 .. $#$phrase) {
        my $note = $d->note->roll;
        $score->n($phrase->[$i], midi_format($note))
    }
}
$score->write_score("$0.mid");
