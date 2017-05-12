#!/usr/bin/perl
use strict;
use NetworkInfo::Discovery::NetBIOS;

print STDERR "usage: $0 IP_addr [IP_addr ...]\n" and exit unless @ARGV;

my $scanner = new NetworkInfo::Discovery::NetBIOS hosts => [ @ARGV ];
$scanner->do_it;

for my $host ($scanner->get_interfaces) {
    printf "<%s> NetBios(node:%s zone:%s)\n", $host->{ip}, 
        $host->{netbios}{node}, $host->{netbios}{zone};
}
