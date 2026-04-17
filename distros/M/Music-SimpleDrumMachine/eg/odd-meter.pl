#!/usr/bin/env perl

# A 3/4 groove

use v5.36;
use Music::SimpleDrumMachine ();

my $port = shift || 'usb';
my $bpm  = shift || 120;
my $chan = shift // 9;

my $dm = Music::SimpleDrumMachine->new(
    port_name => $port,
    bpm       => $bpm,
    chan      => $chan,
    beats     => 12,
    divisions => 3,
    parts     => {
        part_A => \&part_A,
        part_B => \&part_B,
    },
    next_part => 'part_A',
    fills     => {
        fill_A => \&fill_A,
        fill_B => \&fill_B,
    },
    next_fill => 'fill_A',
    verbose   => 1,
);

sub part_A {
    say 'Part A';
    my %patterns = (
        closed => [qw(1 0 1 0 1 0)],
        kick   => [qw(1 0 0 0 0 0)],
        snare  => [qw(0 0 1 0 1 0)],
    );
    my $next = 'part_B';
    return $next, \%patterns;
}
sub part_B {
    say 'Part B';
    my %patterns = (
        closed => [qw(1 1 0 1 1 1 1 1 1 1 1 0)],
        open   => [qw(0 0 1 0 0 0 0 0 0 0 0 1)],
        kick   => [qw(1 0 0 0 0 0 0 0 1 0 1 0)],
        snare  => [qw(0 0 0 0 1 0 0 0 0 0 0 0)],
    );
    my $next = 'part_A';
    return $next, \%patterns;
}
sub fill_A {
    say 'Fill A';
    my %patterns = (
        snare => [qw(1 0 1 0 1 1 0 1 1 0 1 0)],
    );
    my $next = 'fill_B';
    return $next, \%patterns;
}
sub fill_B {
    say 'Fill B';
    my %patterns = (
        snare   => [qw(1 0 1 0 1 1 1 1 0 1 0 1)],
    );
    my $next = 'fill_A';
    return $next, \%patterns;
}