#!/usr/bin/perl

use strict;

use lib 'lib';
use Nmap::Scanner;
$|++;

my $HELP = "$0 target_spec port_spec";

my $targets = shift || die "Missing targets (e.g. \"192.168.1.*\")\n$HELP";
my $ports = shift || die "Missing ports to scan (e.g. 1-1024)\n$HELP";

my $scanner = new Nmap::Scanner;

$scanner->add_target($targets);

$scanner->tcp_syn_scan();
$scanner->debug(1);
$scanner->add_scan_port($ports);
$scanner->ack_icmp_ping();
$scanner->guess_os();
$scanner->add_target($ARGV[0]);
$scanner->max_rtt_timeout(2000);
$scanner->register_scan_complete_event(\&scan_complete);
$scanner->register_scan_started_event(\&scan_started);
$scanner->scan();

sub scan_complete {

    my $self = shift;
    my $host = shift;

    print "Finished scanning ", $host->hostname(),"\n";

    for my $match ($host->os()->osmatches()) {
        print "Host could be of type: " . $match->name(),"\n";
        printf "Nmap is %d%% sure of this\n", $match->accuracy();
    }

    print "Operating system classes as determined by nmap:\n";

    for my $c ($host->os()->osclasses()) {
        print "* " . $c->vendor() . "\n";
        print "- OS generation: " . $c->osgen() . "\n";
        print "- OS family:     " . $c->osfamily() . "\n";
        print "- OS Type:       " . $c->type() . "\n";
        print "- Accuracy:      " . $c->accuracy() . "%\n";
    }

    print "Host has been up since " . $host->os->uptime()->lastboot()."\n"
            if defined $host->os()->uptime();

}

sub scan_started {
    my $self = shift;
    my $host = shift;

    my $hostname = $host->hostname();
    my $ip       = $host->addresses(0)->addr();
    my $status   = $host->status;

    print "$hostname ($ip) is $status\n";

}

