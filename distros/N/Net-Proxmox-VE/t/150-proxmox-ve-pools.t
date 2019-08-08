#!/usr/bin/env perl

use strict;
use warnings;

use Test::More; my $tests = 2; # used later
use Test::Trap;

if ( not $ENV{PROXMOX_TEST_URI} ) {
    my $msg = 'This test sucks.  Set $ENV{PROXMOX_TEST_URI} to a real running proxmox to run.';
    plan( skip_all => $msg );
}
else {
    plan tests => $tests
}

require_ok('Net::Proxmox::VE')
        or die "# Net::Proxmox::VE not available\n";

ok(1, 'stub!');

1;
