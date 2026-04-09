#!/usr/bin/env perl

# Use no auto-fills and only play parts.
# Examples:
#   perl eg/user-defined.pl 'gs wavetable' 90 # on windows
#   perl eg/user-defined.pl fluid 90 # with fluidsynth
#   perl eg/user-defined.pl usb 100 -1 # multi-timbral device

use v5.36;
use Music::SimpleDrumMachine ();

my $port = shift || 'usb';
my $bpm  = shift || 120;
my $chan = shift // 9;

my $dm = Music::SimpleDrumMachine->new(
    port_name => $port,
    bpm       => $bpm,
    chan      => $chan,
    add_drums => [
        { drum => 'open', num => 46 },
        { drum => 'tom', num => 47 },
    ],
    parts     => { part_A => \&part_A, part_B => \&part_B, fill_A => \&fill_A, fill_B => \&fill_B },
    next_part => [qw( part_A part_B fill_A part_A part_B fill_B )],
    filling   => 0,
    verbose   => 1,
);

sub part_A {
    say 'Part A';
    my %patterns = (
        closed => [qw(1 0 1 1 1 0 1 1 1 0 1 1 1 0 0 0)],
        kick   => [qw(1 0 0 0 0 0 0 1 1 0 1 0 0 0 0 0)],
        open   => [qw(0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0)],
        snare  => [qw(0 0 0 0 1 0 0 0 0 0 0 0 1 0 0 0)],
    );
    my $next = '';
    return $next, \%patterns;
}
sub part_B {
    say 'Part B';
    my %patterns = (
        closed => [qw(1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0)],
        open   => [qw(0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1)],
        kick   => [qw(1 0 0 0 0 0 0 0 1 0 1 0 0 0 0 0)],
        snare  => [qw(0 0 0 0 1 0 0 0 0 0 0 0 1 0 0 0)],
        tom    => [qw(0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 0)],
    );
    my $next = '';
    return $next, \%patterns;
}
sub fill_A {
    say 'Fill A';
    my %patterns = (
        snare => [qw(1 0 1 0 1 1 0 1 1 0 1 0 1 1 0 1)],
    );
    my $next = '';
    return $next, \%patterns;
}
sub fill_B {
    say 'Fill B';
    my %patterns = (
        snare => [qw(1 0 1 0 1 1 1 1 0 1 0 1 1 0 0 0)],
        tom   => [qw(0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 1)],
    );
    my $next = '';
    return $next, \%patterns;
}