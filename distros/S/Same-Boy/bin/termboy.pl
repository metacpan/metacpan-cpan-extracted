#!/usr/bin/env perl
use 5.008003;
use strict;
use warnings;
BEGIN { eval { require blib; blib->import } }   # use ./blib in-tree if present
use Same::Boy::Terminal;

# ---------------------------------------------------------------------------
# termboy.pl - a playable terminal frontend for Same::Boy.
#
#   termboy.pl ROM.gbc [--scale N] [--model cgb|dmg|sgb|sgb2|mgb]
#
# See Same::Boy::Terminal for the emulator loop, controls, and rendering.
# ---------------------------------------------------------------------------

my ($rom_path, $scale, $model) = (undef, 1, 'cgb');
while (@ARGV) {
    my $a = shift @ARGV;
    if    ($a eq '--scale') { $scale = shift @ARGV || 1 }
    elsif ($a eq '--model') { $model = shift @ARGV || 'cgb' }
    elsif ($a =~ /^--/)     { die "unknown option $a\n" }
    else                    { $rom_path = $a }
}
die "usage: $0 ROM.gbc [--scale N] [--model cgb|dmg|sgb|sgb2|mgb]\n"
    unless defined $rom_path && -f $rom_path;

my $term = Same::Boy::Terminal->new(
    rom_path => $rom_path,
    scale    => $scale,
    model    => $model,
);

my $had_battery = $term->run;
print "saved battery to ${\ $term->sav_path}\n" if $had_battery;
