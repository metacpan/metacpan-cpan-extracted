#!/usr/bin/perl -w

use strict;
use lib 'lib';
use FindBin qw($Bin);
use Nmap::Scanner;
use constant FILE => "$Bin/../t/router.xml";

my $scanner = Nmap::Scanner->new();
$|++;

$scanner->debug(1);
$scanner->register_scan_complete_event(\&scan_complete);
$scanner->register_scan_started_event(\&scan_started);
$scanner->register_port_found_event(\&port_found);
$scanner->register_no_ports_open_event(\&no_ports);
$scanner->scan_from_file($ARGV[0] || FILE);

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

    print "Finished scanning ", $host->hostname(),"\n";

    my $list = $host->get_port_list();

    while (my $p = $list->get_next()) {
        my $service = "N/A";
        $service = $p->service()->name() if $p->service();
        print join(", ",
                   "Service: " . $service,
                   "  Proto: " . $p->protocol(),
                   " Number: " . $p->portid(),
                   "  State: " . $p->state(), "\n");
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
          join('/', $port->protocol(), $port->portid()),"\n";

}
