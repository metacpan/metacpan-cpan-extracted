#!/usr/bin/env perl

# Play and clock a MIDI device, like a drum machine or sequencer.
# Examples:
#   perl eg/grooves.pl 'gs wavetable' 90 # on windows
#   perl eg/grooves.pl fluid 90 # with fluidsynth
#   perl eg/grooves.pl fluid 100 9 house # change style
#   perl eg/grooves.pl usb 100 -1 # multi-timbral device

use v5.36;
use Data::Dumper::Compact 'ddc';
use MIDI::Drummer::Tiny::Grooves ();
use Music::SimpleDrumMachine ();

my $port = shift || 'usb';
my $bpm  = shift || 120;
my $chan = shift // 9;
my $cat  = shift // 'rock';
my $name = shift // '';

my $grooves = MIDI::Drummer::Tiny::Grooves->new(return_patterns => 1);

my $set;
$set = $grooves->search({ cat => $cat }) if $cat;
$set = $grooves->search({ name => $name }, $set) if $name;
die "No matching grooves for $cat + $name\n" unless keys %$set;

my $dm = Music::SimpleDrumMachine->new(
    port_name => $port,
    bpm       => $bpm,
    chan      => $chan,
    next_part => 'part',
    parts     => { part => \&part },
    verbose   => 1,
);

sub part {
    say 'part';
    my $groove = $grooves->get_groove(0, $set);
    # not crazy about only crashing, like with some funk grooves
    $groove->{groove}{closed} = delete $groove->{groove}{cymbal}
        if !exists($groove->{groove}{closed}) && exists($groove->{groove}{cymbal});
    my %patterns = $grooves->groove($groove->{groove});
    say $groove->{name}, ' ', ddc \%patterns;
    my $next = 'part';
    return $next, \%patterns;
}