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
    tonic    => 'C',
    scale    => 'major',
    octave   => 4,
    bpm      => 80,
    factor   => 7, # for volume changes
    triplets => 0, # add triplets to the melody phrase
    quality  => 0, # use chord qualities
);
GetOptions(\%opt,
    'tonic=s',
    'scale=s',
    'octave=i',
    'bpm=i',
    'triplets',
    'quality',
);

my $score = setup_score(bpm => $opt{bpm});

my $cn = Music::Chord::Note->new;

my $d = Music::Dice->new(
    scale_note => $opt{tonic},
    scale_name => $opt{scale},
);
 
my $c_phrase = $d->rhythmic_phrase->roll; # harmony
print "H: @{ $c_phrase }\n";
if ($opt{triplets}) {
    my $pool    = $d->phrase_pool;
    my $weights = $d->phrase_weights;
    my $groups  = $d->phrase_groups;
    $d->phrase_pool([ @$pool, qw(thn tqn) ]);
    $d->phrase_weights([ @$weights, 2, 2 ]);
    $d->phrase_groups([ @$groups, 3, 3 ]);
}
my $m_phrase = $d->rhythmic_phrase->roll; # melody
print "M: @{ $m_phrase }\n";
my $tonic    = $d->note->roll;
my $mode     = $d->mode->roll;
my @scale    = get_scale_notes($tonic, $mode);
print "$tonic $mode: @scale\n";
print "degree => chord | duruation\n";
my @bass_notes;

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
        if ($opt{quality} && $i == $#$c_phrase) {
            if ($triad eq 'diminished') {
                $type = $d->chord_quality_diminished->roll;
            }
            elsif ($triad eq 'minor') {
                $type = $d->chord_quality_minor->roll;
            }
            else {
                $type = $d->chord_quality_major->roll;
            }
        }
        my $chord = "$scale[$index]$type";
        print "$degree => $chord | $c_phrase->[$i]\n";
        my @tones = $cn->chord_with_octave($chord, $opt{octave});
        $score->n($c_phrase->[$i], midi_format(@tones));
        push @bass_notes, $scale[$index] if $i == 0;
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
    my $note = shift(@bass_notes) . ($opt{octave} - 1);
    $score->n('wn', midi_format($note));
    $score->Volume($volume);
}
