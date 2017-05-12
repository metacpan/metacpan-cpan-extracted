#!/usr/bin/perl

use lib 'lib';

use Nmap::Scanner;
$|++;

use strict;

my $scanner = Nmap::Scanner->new();

# $Nmap::Scanner::DEBUG = 1;

my $hosts = $ARGV[0] || 
                die "Missing host spec (e.g. localhost)\n$0 host_spec port_spec\n";
my $ports = $ARGV[1] || 
                die "Missing port spec (e.g. 1-1024)\n$0 host_spec port_spec\n";

$scanner->register_scan_complete_event(\&scan_complete);
$scanner->register_scan_started_event(\&scan_started);
$scanner->register_port_found_event(\&port_found);
$scanner->register_no_ports_open_event(\&no_ports);
$scanner->scan("-sT -P0 -O --max_rtt_timeout 300 -p $ports $hosts");

sub no_ports {
    my $self       = shift;
    my $host       = shift;
    my $extraports = shift;

    my $name = $host->hostname();
    my $addresses = join(',', map {$_->addr()} @{$host->addresses()});
    my $state = $extraports->state();

    print "All ports on host $name ($addresses) are in state $state\n";
}

sub scan_complete {

    my $self      = shift;
    my $host      = shift;

    # print $host->as_xml();

    print "Finished scanning ", $host->hostname(),":\n";

    my $guess = $host->os();

    if ($guess) {

        my @matches = $host->os()->osmatches();
        my $uptime = $guess->uptime;

        print "  * Host has been up since " . $uptime->lastboot() . "\n"
            if (defined($uptime) && $uptime->lastboot() ne '');

        my $t = $guess->tcpsequence();

        print "  * TCP Sequence difficulty: " . $t->difficulty(),"\n"
            if $t->difficulty();

        if (scalar(@matches) > 0) {

            print "  * OS guesses:\n";

            for my $match (@matches) {
                print "    o " . $match->name() . " / (". 
                                 $match->accuracy() . "% sure)\n";
            }

        }

    } else {

        print "Can't figure out what OS ",$host->hostname()," has.\n";

    }

}

sub scan_started {

    my $self     = shift;
    my $host     = shift;

    my $hostname = $host->hostname();
    my $addresses = join(',', map {$_->addr()} $host->addresses());
    my $status = $host->status();

    print "$hostname ($addresses) is $status\n";

}

sub port_found {

    my $self     = shift;
    my $host     = shift;
    my $port     = shift;

    my $name = $host->hostname();
    my $addresses = join(',', map {$_->addr()} $host->addresses());

    print "On host $name ($addresses), found ",
          $port->state()," port ",
          join('/',$port->protocol(), $port->portid()),"\n";

}
