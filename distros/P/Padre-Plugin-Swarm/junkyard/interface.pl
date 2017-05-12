#!/usr/bin/perl
use IO::Interface::Simple;

my @interfaces = IO::Interface::Simple->interfaces;
print $_,$/ for @interfaces;

foreach my $i ( @interfaces ) {
    print $i, $/;
    print "\trunning:", $i->is_running, $/;
    print "\tmulticast:", $i->is_multicast, $/;
    print "\taddress:", $i->address , $/;
    print $/;
    
    
}