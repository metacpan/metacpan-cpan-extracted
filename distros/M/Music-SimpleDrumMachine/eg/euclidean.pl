#!/usr/bin/env perl

# Play and clock a MIDI device, like a drum machine or sequencer.
# Examples:
#   perl eg/euclidean.pl 'gs wavetable' 90 # on windows
#   perl eg/euclidean.pl fluid 90 # with fluidsynth
#   perl eg/euclidean.pl usb 100 -1 # multi-timbral device

use v5.36;
use Math::Prime::XS qw(primes);
use Music::CreatingRhythms ();
use Music::SimpleDrumMachine ();

my %primes = ( # for computing patterns
    all  => [ primes(16) ],
    to_5 => [ primes(5) ],
    to_7 => [ primes(7) ],
);

my $mcr = Music::CreatingRhythms->new;

my $dm = Music::SimpleDrumMachine->new(
    port_name => shift || 'usb',
    bpm       => shift || 120,
    chan      => shift // 9,
    next_part => 'part_A',
    parts     => {
        part_A => \&part_A,
        part_B => \&part_B,
        part_C => \&part_C,
    },
    verbose => 1,
);

sub part_A {
    say 'part A';
    # choose random primes to use by the hihat, kick, and snare
    my ($p, $q, $r) = primes_list(\%primes);
    my %patterns = (
        closed => $mcr->euclid($p, 16),
        kick   => $mcr->euclid($q, 16),
        snare  => $mcr->rotate_n($r, $mcr->euclid(2, 16)),
    );
    my $next = 'part_B';
    return $next, \%patterns;
}

sub part_B {
    say 'part B';
    # choose a random prime to use by the hihat
    my ($p) = primes_list(\%primes);
    my %patterns = (
        closed => $mcr->euclid($p, 16),
        kick   => [qw(1 0 0 0 0 0 0 0 1 0 0 0 0 0 0 1)],
        snare  => [qw(0 0 0 0 1 0 0 0 0 0 0 0 1 0 1 0)],
    );
    my $next = 'part_C';
    return $next, \%patterns;
}

sub part_C {
    say 'part C';
    # choose a random prime to use by the hihat
    my ($p) = primes_list(\%primes);
    my %patterns = (
        closed => $mcr->euclid($p, 16),
        kick   => [qw(1 0 0 0 0 0 0 0 1 0 1 0 0 0 0 0)],
        snare  => [qw(0 0 0 0 1 0 0 0 0 0 0 0 1 0 0 0)],
    );
    my $next = 'part_A';
    return $next, \%patterns;
}

sub primes_list($primes) {
    return map { $primes->{$_}[ int rand $primes->{$_}->@* ] } sort keys %$primes;
}