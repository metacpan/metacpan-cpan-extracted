#!/usr/bin/perl

use Sys::Virt;
use Data::Dumper;

my $c = Sys::Virt->new(uri => "qemu:///system",
		       readonly => 1);

$n = $c->get_network_by_name("default");

foreach my $lease ($n->get_dhcp_leases()) {
    print Dumper($lease);
}
