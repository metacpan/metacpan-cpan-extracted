#!/usr/bin/env perl

use v5.36;

use Music::SimpleDrumMachine ();

my $port_name = shift || 'usb';
my $bpm       = shift || 120;
my $chan      = shift // 9;

my $dm = Music::SimpleDrumMachine->new(
    port_name => $port_name,
    bpm       => $bpm,
    chan      => $chan,
    next_part => 'part_A',
    parts     => { part_A => \&part_A },
    verbose   => 1,
);

sub part_A {
    say 'part A';
    my %patterns = (
        hihat => [qw(1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0)],
        open  => [qw(0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1)],
        kick  => [qw(1 0 0 0 0 0 0 0 1 0 1 0 0 0 0 0)],
        snare => [qw(0 0 0 0 1 0 0 0 0 0 0 0 1 0 0 0)],
    );
    my $next = 'part_A';
    return $next, \%patterns;
}