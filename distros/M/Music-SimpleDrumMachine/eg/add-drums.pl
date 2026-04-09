#!/usr/bin/env perl

# Add drums, a part, and a fill.
# Examples:
#   perl eg/add-drums.pl 'gs wavetable' 90 # on windows
#   perl eg/add-drums.pl fluid 90 # with fluidsynth
#   perl eg/add-drums.pl usb 100 -1 # multi-timbral device

use Music::SimpleDrumMachine ();

my $port_name = shift || 'usb';
my $bpm       = shift || 120;
my $chan      = shift // 9;

my $dm = Music::SimpleDrumMachine->new(
    port_name => $port_name,
    bpm       => $bpm,
    chan      => $chan,
    add_drums => [
        { drum => 'tom', num => 47 },
        { drum => 'open', num => 46 },
        { drum => 'china', num => 52 },
    ],
    parts      => { part_A => \&part_A },
    next_part  => 'part_A',
    fills      => { fill_A => \&fill_A },
    next_fill  => 'fill_A',
    fill_crash => 0,
    velo_min   => 0,
    velo_max   => 0,
    velo_off   => 127,
    verbose    => 1,
);

sub part_A {
    print "part_A\n";
    my %patterns = (
        closed => [qw(1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0)],
        open   => [qw(0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1)],
        kick   => [qw(1 0 0 0 0 0 0 0 1 0 1 0 0 0 0 0)],
        snare  => [qw(0 0 0 0 1 0 0 0 0 0 0 0 1 0 0 0)],
        tom    => [qw(0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 0)],
        china  => [qw(0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0)],
    );
    my $next = 'part_A';
    return $next, \%patterns;
}
sub fill_A {
    print "fill A\n";
    my %patterns = (
        snare => [qw(1 0 1 0 1 1 1 1 0 1 0 1 1 0 0 0)],
        tom   => [qw(0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 1)],
    );
    my $next = 'fill_A';
    return $next, \%patterns;
}