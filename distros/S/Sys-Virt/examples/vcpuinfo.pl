# -*- perl -*-
use strict;
use warnings;
use Sys::Virt;

my $addr = @ARGV ? shift @ARGV : "";
print "Addr $addr\n";
my $con = Sys::Virt->new(address => $addr, readonly => 1);

print "VMM type: ", $con->get_type(), "\n";

foreach my $dom (sort { $a->get_id <=> $b->get_id } $con->list_all_domains) {
    print "Domain: {\n";
    print "  ID: ", $dom->get_id(), " '" , $dom->get_name(), "'\n";
    print "  UUID: ", $dom->get_uuid_string(), "\n";
    my $nodeinfo = $con->get_node_info;
    my @info = $dom->get_vcpu_info(Sys::Virt::Domain::AFFECT_CONFIG);

    foreach my $info (@info) {
	print "  VCPU: {\n";
	foreach (sort { $a cmp $b } keys %{$info}) {
	    if ($_ eq "affinity") {
		print "    ", $_, ": ";
                my @mask = split(//, unpack("b$nodeinfo->{cpus}", $info->{$_}));
                print join ("", @mask), "\n";
		print "\n";
	    } else {
		print "    ", $_, ": ", $info->{$_}, "\n";
	    }
	}
	print "  }\n";
    }
    print "}\n";
}
