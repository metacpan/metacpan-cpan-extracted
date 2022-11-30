#!/usr/bin/perl

use strict;
use warnings;

use PDL;
use PDL::IO::Touchstone qw/rsnp/;
use RF::Component;

use Test::More tests => 3;

# This is a simple test, just make sure frequency counts and values are right.
# The choise to test ESR is arbitrary:

my $c = RF::Component->load('t/test-data/cha3024-99f-lna.s2p');

my $data = pdl [-13038.638, 974.1204, 3287.2506, 4563.1612, 3851.8406,
	1733.9423, 341.83503, 157.27215, -1133.7421, -1051.3163];

ok(all(abs($data - $c->at('1e9 - 10e9 x10')->esr) < 1e-3), "ESR matches");

ok($c->at(1e9)->freqs->nelem == 1, "nelem == 1");
ok($c->at('1e9 - 2e9 x4')->freqs->nelem == 4, "nelem == 4");
