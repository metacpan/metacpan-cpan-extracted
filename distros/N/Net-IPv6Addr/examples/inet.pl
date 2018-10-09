#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use Net::IPv6Addr;
my $obj = Net::IPv6Addr->new ('dead:beef:cafe:babe:dead:beef:cafe:babe');
if ($obj->in_network ('dead:beef:ca0::/21')) {
    print $obj->to_string_compressed, " is in network.\n";
}


