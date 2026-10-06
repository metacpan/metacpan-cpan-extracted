#!/usr/bin/env perl

# Just like euclidean.pl but with a save attribute and weighted next
# part probability.

use v5.36;
use Math::Prime::XS qw(primes);
use Music::CreatingRhythms ();
use Music::SimpleDrumMachine ();

my $name = shift || 'usb';
my $bpm  = shift || 120;
my $chan = shift // 9;
my $file = shift || "$0.mid";

my $beats  = 16;
my %primes = ( # for computing patterns
    all  => [ primes($beats) ],
    to_5 => [ primes(5) ],
    to_7 => [ primes(7) ],
);

my $next_part = { part_A => 6, part_B => 3, part_C => 2 }; 

my $mcr = Music::CreatingRhythms->new;

my $dm = Music::SimpleDrumMachine->new(
    port_name => $name,
    bpm       => $bpm,
    chan      => $chan,
    next_part => $next_part,
    parts     => {
        part_A => \&part_A,
        part_B => \&part_B,
        part_C => \&part_C,
    },
    save    => $file,
    verbose => 1,
);

sub part_A {
    say 'part A';
    # choose random primes to use by the hihat, kick, and snare
    my ($p, $q, $r) = primes_list(\%primes);
    my %patterns = (
        closed => $mcr->euclid($p, $beats),
        kick   => $mcr->euclid($q, $beats),
        snare  => $mcr->rotate_n($r, $mcr->euclid(2, $beats)),
    );
    return $next_part, \%patterns;
}

sub part_B {
    say 'part B';
    # choose a random prime to use by the hihat
    my ($p) = primes_list(\%primes);
    my %patterns = (
        closed => $mcr->euclid($p, $beats),
        kick   => [qw(1 0 0 0 0 0 0 0 1 0 0 0 0 0 0 1)],
        snare  => [qw(0 0 0 0 1 0 0 0 0 0 0 0 1 0 1 0)],
    );
    return $next_part, \%patterns;
}

sub part_C {
    say 'part C';
    # choose a random prime to use by the hihat
    my ($p, $q) = primes_list(\%primes);
    my %patterns = (
        closed => $mcr->euclid($p, $beats),
        open   => $mcr->euclid($q, $beats),
        kick   => [qw(1 0 0 0 0 0 0 0 1 0 1 0 0 0 0 0)],
        snare  => [qw(0 0 0 0 1 0 0 0 0 0 0 0 1 0 0 0)],
    );
    return $next_part, \%patterns;
}

sub primes_list($primes) {
    return map { $primes->{$_}[ int rand $primes->{$_}->@* ] } sort keys %$primes;
}
