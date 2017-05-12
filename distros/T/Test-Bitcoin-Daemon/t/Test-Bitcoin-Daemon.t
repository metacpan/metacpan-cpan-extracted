#!/usr/bin/env perl
use 5.014;
use strict;
use warnings;

use Test::More;
use File::Which;

if ( which("bitcoind") ) {
    plan tests => 2;
    use_ok("Test::Bitcoin::Daemon");
    my $bitcoind = new Test::Bitcoin::Daemon;
    my $clicmd = $bitcoind->clicmd;
    ok( `$clicmd getinfo` =~ /"testnet" : true/, "Testnet instance" );
} else {
    plan skip_all => "Cannot run tests if no bitcoind found";
}
