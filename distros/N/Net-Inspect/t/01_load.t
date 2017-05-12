#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;

eval <<'EVAL';
use Net::Inspect;
use Net::Inspect::L2::Pcap;
use Net::Inspect::L3::IP;
use Net::Inspect::L4::TCP;
use Net::Inspect::L4::UDP;
use Net::Inspect::L5::GuessProtocol;
use Net::Inspect::L5::NoData;
use Net::Inspect::L5::Unknown;
use Net::Inspect::L7::HTTP;
use Net::Inspect::L7::HTTP::Request::Simple;
use Net::Inspect::L7::HTTP::Request::InspectChain;
EVAL

cmp_ok( $@,'eq','', 'loading Net::Inspect*' );
