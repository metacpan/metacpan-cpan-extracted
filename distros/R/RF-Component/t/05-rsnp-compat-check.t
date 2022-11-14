#!/usr/bin/perl

use strict;
use warnings;

use PDL;
use PDL::IO::Touchstone qw/rsnp/;
use RF::Component;

use Test::More tests => 1;

# This verifies compatibility since get_wsnp_list is maintained separately from
# the return value of rsnp().  For example, if noise parameter reading is added
# to rsnp() then this test will fail so we can be sure to add support for that
# in ->load.  

my @rsnp = rsnp('t/test-data/cha3024-99f-lna.s2p');
my $c = RF::Component->load('t/test-data/cha3024-99f-lna.s2p');

my @wsnp = $c->get_wsnp_list;

ok(scalar(@wsnp) == scalar(@rsnp), "wsnp list is same length asn rsnp");
