#!/usr/bin/perl

# This script talks to Native Instrument's Reaktor

use strict;
use warnings;
use Net::OpenSoundControl::Client;

my $client = Net::OpenSoundControl::Client->new(Port => 10000)
  or die "Could not start Client: $@\n";

$| = 1;

while (1) {
    $client->send(['#bundle', 1, ['/Pitch', 'f', rand(1)]]);
    print ".";
    sleep(1);
}
