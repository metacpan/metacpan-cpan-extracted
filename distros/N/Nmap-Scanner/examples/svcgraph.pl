#!/usr/bin/perl

#
#  This program will print a textual graph showing how many hosts have what
#  type of services on them.  It can take a while to run depending on how 
#  many hosts you are scanning.
#
#  USAGE: svcgraph.pl host_spec port_spec
#
#  Ex: svcgraph.pl 192.168.192.1-255 1-1024
#

use lib 'lib';
use Nmap::Scanner;
use strict;
use Text::BarGraph;

my %HOSTS;
my $scan = new Nmap::Scanner();

$scan->tcp_syn_scan();
$scan->add_target($ARGV[0] ||
                      die "Missing host to scan!\n$0 host ports\n");
$scan->add_scan_port($ARGV[1] ||
                      die "Missing ports to scan!\n$0 host ports\n");

my $hosts = $scan->scan()->get_host_list();

my $COUNT;

while (my $host = $hosts->get_next()) {

    $COUNT++;

    my $ports = $host->get_port_list();

    while (my $port = $ports->get_next()) {
        next unless lc($port->state()) eq 'open';
        $HOSTS{$port->service()->name()}++;
    }

}


my $b = Text::BarGraph->new();
$b->{'color'} = 1;
$b->{'num'} = 1;
$b->{'sort'} = 'key';

print $b->graph(\%HOSTS);
my $total = 0;
map { $total += $_} values %HOSTS;

print <<EOF;
==============================================================
$total open ports found on $COUNT hosts.
EOF

