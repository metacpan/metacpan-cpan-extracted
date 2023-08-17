#!/usr/local/bin/perl -w
### Script to convert CISCO-PRODUCTS-MIB.my to a Perl variable
### definition for use in e.g. etna:/home/noc/bin/get-cisco-versions.
### Should be run from time to time when a new MIB arrives on
### ftp.cisco.com/pub/mibs/v2.
###
use strict;

my $source = "/home/leinen/snmp/mibs/cisco/v2/CISCO-PRODUCTS-MIB.my";

open (SRC, $source) || die "open $source: $!";
print "my %cisco_product_name = (\n";
while (<SRC>) {
    my ($product, $octet);
    next unless ($product, $octet)
	= /^(.*)\s+OBJECT\s+IDENTIFIER\s*::=\s*{\s*ciscoProducts\s*([0-9]+)\s*}/;
    print "  $octet => \"$product\",\n";
}
close (SRC) || warn "close $source: $!";
print ");\n";
1;
