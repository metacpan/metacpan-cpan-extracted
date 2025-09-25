#!/usr/bin/env perl
use strict;
use warnings;

use Data::Dumper::Compact qw(ddc);
use MIDI::Util qw(setup_score midi_format);
use Music::MelodicDevice::Arpeggiation ();
use Music::Chord::Progression ();

my $prog = Music::Chord::Progression->new(
    max => 16,
    scale_name => 'wholetone',
    net => {
        1 => [2,3,4,5,6],
        2 => [1,3,4,5,6],
        3 => [1,2,4,5,6],
        4 => [1,2,3,5,6],
        5 => [1,2,3,4,6],
        6 => [1,2,3,4,5],
    },
    chord_map => [('7') x 6], # every chord is the same flavor
    substitute => 1,
    verbose => 0,
);
my $chords = $prog->generate;
# warn ddc($chords)

my $arp = Music::MelodicDevice::Arpeggiation->new;

my $score = setup_score(bpm => 100);

for my $c (@$chords) {
    my $arped = $arp->arp($c, 1, 'updown');
    for my $n (@$arped) {
      $score->n(midi_format(@$n));
    }
}

$score->write_score("$0.mid");
