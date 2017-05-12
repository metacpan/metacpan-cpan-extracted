#!/usr/bin/perl

use lib 'lib';

use Nmap::Scanner;
use Text::Diff;

use strict;

#
#  Show how to diff scans of OS guesses of two machines easily :)
#

my $HELP = "$0 host1 host2";

my $host1 = shift || die "Missing host 1\n$HELP";
my $host2 = shift || die "Missing host 2\n$HELP";

sub do_scan {
    my $scanner = new Nmap::Scanner;

    $scanner->tcp_syn_scan();
    $scanner->add_scan_port('21');
    $scanner->ack_icmp_ping();
    $scanner->guess_os();
    $scanner->add_target(shift());
    $scanner->max_rtt_timeout(200);

    my $results = $scanner->scan();

    return $results->get_host_list()->get_next()->os()->as_xml();

}

my $results1 = do_scan($host1);
my $results2 = do_scan($host2);

print diff(\$results1, \$results2, { STYLE => 'Unified' });

