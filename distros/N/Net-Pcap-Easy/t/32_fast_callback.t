#!/usr/bin/perl

use strict;
use Net::Pcap::Easy;
use File::Slurp qw(slurp);

use Test;

plan tests => 6;

my $npe = Net::Pcap::Easy->new(
    dev              => "file:dat/lo.data",
    packets_per_loop => 1,
);

# NOTE: when using fast callbacks, $npe never returns the number of processed
# packets since it didn't process any packets

$npe->loop(sub { ok(1) }) for 1 .. 100;
