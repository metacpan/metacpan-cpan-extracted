#!/usr/bin/perl

use strict;
use lib 'lib';
use Nmap::Scanner;

my $help = "$0 host ports";

my $scanner = new Nmap::Scanner;

$scanner->tcp_syn_scan();
$scanner->udp_scan();
$scanner->add_scan_port($ARGV[1]) || die "Missing PORTS to scan!\n$help";
$scanner->ack_icmp_ping();
$scanner->guess_os();
$scanner->add_target($ARGV[0] || die "Missing host to scan!\n$help");
$scanner->max_rtt_timeout(200);
my $results = $scanner->scan();

print $results->as_xml();
