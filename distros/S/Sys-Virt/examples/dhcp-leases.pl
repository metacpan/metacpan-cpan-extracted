#!/usr/bin/perl

use Sys::Virt;

my $c = Sys::Virt->new(uri => "qemu:///system",
		       readonly => 1);

$n = $c->get_network_by_name("default");

foreach my $lease ($n->get_dhcp_leases()) {
    print "Interface ", $lease->{iface}, "\n";
    print "   MAC: ", $lease->{mac}, "\n";
    print "    IP: ", $lease->{ipaddr}, "\n";
    print "  Host: ", $lease->{hostname}, "\n" if $lease->{hostname};
    print "\n";
}
