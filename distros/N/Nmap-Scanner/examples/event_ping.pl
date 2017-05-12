#!/usr/bin/perl

use lib 'lib';

use Nmap::Scanner;
$|++;

use strict;

my $scanner = new Nmap::Scanner;

my $target_spec = "$ARGV[0]" || 
                  die "Missing target spec\n$0 target_spec (e.g. 192.168.1.1)\n";
$scanner->ping_scan();
$scanner->ack_icmp_ping();
$scanner->add_target($target_spec);
$scanner->register_scan_started_event(\&scan_started);
$scanner->scan();

sub scan_started {
    my $self = shift;
    my $host = shift;

    my $hostname = $host->hostname();
    my $ip       = ($host->addresses)[0]->addr();
    my $status   = $host->status;

    print "$hostname ($ip) is $status\n";

}
