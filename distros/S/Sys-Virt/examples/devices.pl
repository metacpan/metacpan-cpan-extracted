# -*- perl -*-
use strict;
use warnings;
use Sys::Virt;

my $addr = @ARGV ? shift @ARGV : undef;

my $con = Sys::Virt->new(address => $addr, readonly => 1);


my @devs = $con->list_node_devices("net");

print "Available NICS\n";
foreach (@devs) {
    print "NIC: ", $_->get_name(), "\n";
}
