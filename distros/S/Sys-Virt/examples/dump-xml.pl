# -*- perl -*-

use strict;
use warnings;
use Sys::Virt;

my $addr = "";
if (@ARGV == 2) {
    $addr = shift @ARGV;
}

if (@ARGV != 1) {
    print STDERR "syntax: $0 [URI] DOMAIN-NAME\n";
    exit 1;
}

my $con = Sys::Virt->new(address => $addr, readonly => 1);

my $name = shift @ARGV;

my $dom = $con->get_domain_by_name($name);

print $dom->get_xml_description(), "\n";

