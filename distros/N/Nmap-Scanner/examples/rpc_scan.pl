#!/usr/bin/perl

use lib 'lib';
use Nmap::Scanner;
use strict;

my $scanner = new Nmap::Scanner;

$scanner->rpc_scan();
$scanner->ack_icmp_ping();
$scanner->add_target($ARGV[0] || 
                         die "Missing host spec!\n$0 host_spec\n");
$scanner->max_rtt_timeout(300);
$scanner->register_port_found_event(\&found_port);
$scanner->scan();

sub found_port {

    my $self = shift;
    my $host = shift;
    my $port = shift;

    my $name = $host->hostname();
    my $ip   = join(',',map {$_->addr()} $host->addresses());
    my $proto = $port->protocol();

    my $service = $port->service();

    return unless ($service && $service->proto() eq 'rpc');

    print "$name ($ip), port ",$port->portid(), '/', $proto;

    print ' ', $service->name(), ": ", $service->rpcnum(),
          '[low: ', $service->lowver(), ', high: ', $service->highver(), '] ',
          ' - ', $service->extrainfo(), "\n";

}
