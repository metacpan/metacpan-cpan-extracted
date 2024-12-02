#!/usr/bin/env perl
use strict;
use warnings;

use Data::Dumper::Compact qw(ddc);
use Getopt::Long qw(GetOptions);
use MIDI::Util qw(setup_score set_chan_patch midi_format);
use Music::Chord::Note ();
use Music::Dice ();
use Music::Scales qw(get_scale_notes);

my %opt = (
    tonic  => 'C',
    scale  => 'major',
    octave => 4,
    bpm    => 80,
    factor => 7, # for volume changes
);
GetOptions(\%opt,
    'tonic=s',
    'scale=s',
    'octave=i',
    'bpm=i',
);

my $score = setup_score(bpm => $opt{bpm});

my $cn = Music::Chord::Note->new;

my $d = Music::Dice->new(
    scale_note => $opt{tonic},
    scale_name => $opt{scale},
);
 
my $c_phrase = $d->rhythmic_phrase->roll; # harmony
# print "H: @{ $c_phrase }\n";
my $m_phrase = $d->rhythmic_phrase->roll; # melody
# print "M: @{ $m_phrase }\n";
my $tonic    = $d->note->roll;
my $mode     = $d->mode->roll;
my @scale    = get_scale_notes($tonic, $mode);
print "$tonic $mode: @scale\n";
print "degree => chord | duruation\n";

$d = Music::Dice->new(
    scale_note => $tonic,
    scale_name => $mode,
);

$score->synch(
    \&harmony,
    \&melody,
    \&bass,
) for 1 .. 8;
$score->write_score("$0.mid");

sub harmony {
    set_chan_patch($score, 0, 4);
    my $volume = $score->Volume;
    $score->Volume($volume - $opt{factor});
    for my $i (0 .. $#$c_phrase) {
        my ($degree, $triad) = $d->mode_degree_triad_roll($mode);
        my $index = $degree - 1;
        my $type = $triad eq 'diminished' ? 'dim' : $triad eq 'minor' ? 'm' : '';
        my $chord = "$scale[$index]$type";
        print "$degree => $chord | $c_phrase->[$i]\n";
        my @tones = $cn->chord_with_octave($chord, $opt{octave});
        $score->n($c_phrase->[$i], midi_format(@tones));
    }
    $score->Volume($volume);
}

sub melody {
    set_chan_patch($score, 1, 5);
    for my $i (0 .. $#$m_phrase) {
        my $note = $d->note->roll . ($opt{octave} + 1);
        $score->n($m_phrase->[$i], midi_format($note));
    }
}

sub bass {
    set_chan_patch($score, 2, 33);
    my $volume = $score->Volume;
    $score->Volume($volume + $opt{factor});
    my $note = $d->note->roll . ($opt{octave} - 1);
    $score->n('wn', midi_format($note));
    $score->Volume($volume);
}
