# -*- perl -*-
use strict;
use warnings;
use Sys::Virt;

my $addr = @ARGV ? shift @ARGV : "";
print "Addr $addr\n";
my $con = Sys::Virt->new(address => $addr, readonly => 1);

print "VMM type: ", $con->get_type(), "\n";

print "Node: {\n";
my $ninfo = $con->get_node_info;
foreach (sort { $a cmp $b } keys %{$ninfo}) {
    print "  ", $_, ": ", $ninfo->{$_}, "\n";
}
print "}\n";

print "libvirt Version: ", $con->get_major_version(), ".", $con->get_minor_version(), ".", $con->get_micro_version(), "\n";
foreach my $dom (sort { $a->get_id <=> $b->get_id } $con->list_domains) {
    print "Domain: {\n";
    print "  ID: ", $dom->get_id(), " '" , $dom->get_name(), "'\n";
    print "  UUID: ", $dom->get_uuid_string(), "\n";
    my $info = $dom->get_info;
    foreach (sort { $a cmp $b } keys %{$info}) {
	print "  ", $_, ": ", $info->{$_}, "\n";
    }
    print "}\n";
}
