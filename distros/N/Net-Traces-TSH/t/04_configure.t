# Test correct operation of Net::Traces::TSH configure()
#
use strict;
use Test;

BEGIN { plan tests => 9 };
use Net::Traces::TSH 0.13 qw( configure verbose);
ok(1);

# Default link capacity value
#
ok($Net::Traces::TSH::options{'Link Capacity'} == 0);

configure('Link Capacity' => 100_000_000);

ok($Net::Traces::TSH::options{'Link Capacity'} == 100_000_000);

verbose;

ok($Net::Traces::TSH::options{Verbosity} == 1);

configure(Verbosity => 0);

ok($Net::Traces::TSH::options{Verbosity} == 0);

configure(Verbosity => 1);

ok($Net::Traces::TSH::options{Verbosity} == 1);

configure('some random option' => 1);

ok( !defined $Net::Traces::TSH::options{'some random option'} );

configure(tcpdump => 'trace.tcpdump');

ok($Net::Traces::TSH::options{tcpdump});

configure(ns2 => 'trace.ns2');

ok($Net::Traces::TSH::options{ns2});
