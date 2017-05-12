#!/usr/bin/perl -T
use strict;
use Test::More;
BEGIN { plan tests => 2 }

BEGIN {
  use_ok('Net::Pcap');
}

my $pcap = Net::Pcap->VERSION;
ok( $pcap );

diag(<<"WARNING") if $pcap lt '0.05';
Please note that you are using a old version ($Net::Pcap::VERSION) of Net::Pcap.
We suggest you to upgrade to version 0.05 or later in order 
to have more functionalities. 
WARNING

