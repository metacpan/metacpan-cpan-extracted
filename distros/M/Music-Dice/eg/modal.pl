#!/usr/bin/env perl
use strict;
use warnings;

use Data::Dumper::Compact qw(ddc);
use Getopt::Long qw(GetOptions);
use MIDI::Util qw(setup_score midi_format);
use Music::Chord::Note ();
use Music::Dice ();
use Music::Scales qw(get_scale_notes);

my %opt = (
    tonic  => 'C',
    scale  => 'major',
    octave => 4,
    bpm    => 80,
);
GetOptions(\%opt,
    'tonic=s',
    'scale=s',
    'octave=i',
    'bpm=i',
);

my $score = setup_score(patch => 0, bpm => $opt{bpm});

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
$score->write_score("$0.mid");
