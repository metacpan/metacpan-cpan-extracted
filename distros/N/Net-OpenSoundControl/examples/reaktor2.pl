#!/usr/bin/perl

# This script talks to Native Instrument's Reaktor

use strict;
use warnings;
use Net::OpenSoundControl::Client;

my $client = Net::OpenSoundControl::Client->new(Port => 10000)
  or die "Could not start Client: $@\n";

$| = 1;

my $val   = 0;
my $delta = 0.01;

while (1) {
    $client->send(['#bundle', 1, ['/Pitch', 'f', $val]]);
    $client->send(['#bundle', 1, ['/Fader', 'f', (1 - $val) / 6]]);

    if ($val > 1) {
        $val   = 1;
        $delta = -$delta;
    }

    if ($val < 0) {
        $val   = 0;
        $delta = -$delta;
    }

    $val += $delta;

    my $i = 0;
    $i++ for (0 .. 10_000);
}
