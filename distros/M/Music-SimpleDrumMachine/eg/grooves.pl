#!/usr/bin/env perl

# Play and clock a MIDI device, like a drum machine or sequencer.
# Examples:
#   perl eg/grooves.pl 'gs wavetable' 90 # on windows
#   perl eg/grooves.pl fluid 90 # with fluidsynth
#   perl eg/grooves.pl usb 100 -1 # multi-timbral device

use v5.36;
use Data::Dumper::Compact 'ddc';
use MIDI::Drummer::Tiny::Grooves ();
use Music::SimpleDrumMachine ();

my $port  = shift || 'usb';
my $bpm   = shift || 120;
my $chan  = shift // 9;
my $style = shift || 'rock';

my $grooves = MIDI::Drummer::Tiny::Grooves->new(return_patterns => 1);
my $set = $grooves->search({ cat => $style });

my $dm = Music::SimpleDrumMachine->new(
    port_name => $port,
    bpm       => $bpm,
    chan      => $chan,
    add_drums => [
        { drum => 'open', num => 46 },
        { drum => 'cymbal', num => 57 },
    ],
    next_part => 'part',
    parts     => { part => \&part },
    verbose   => 1,
);

sub part {
    say 'part';
    my $groove = $grooves->get_groove(0, $set);
    my %patterns = $groove->{groove}->();
    say $groove->{name}, ' ', ddc \%patterns;
    my $next = 'part';
    return $next, \%patterns;
}