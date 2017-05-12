# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Net-Tshark.t'

#########################

use Test::More tests => 3;
BEGIN { use_ok('Net::Tshark') };
BEGIN { use_ok('Net::Tshark::Field') };
BEGIN { use_ok('Net::Tshark::Packet') };

#########################



