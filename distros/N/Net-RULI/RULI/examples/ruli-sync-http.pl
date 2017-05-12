#! /usr/bin/perl -w
#
# $Id: ruli-sync-http.pl,v 1.1 2004/10/13 20:11:27 evertonm Exp $

use strict;
use Net::RULI;

if (($#ARGV < 0) || ($#ARGV > 1)) {
    die <<__EOF__;
usage:   $0 domain [force_port]

example: $0 registro.br
__EOF__
}

my ($domain, $force_port) = @ARGV;

if (!defined($force_port)) {
	$force_port = -1;
}

my $srv_list_ref = Net::RULI::ruli_sync_http_query($domain, $force_port, 0);
if (!defined($srv_list_ref)) {
    warn "$domain query failed\n";
    exit(1);
}

print $domain, "\n";

foreach (@$srv_list_ref) {
    my $target = $_->{target};
    my $priority = $_->{priority};
    my $weight = $_->{weight};
    my $port = $_->{port};
    my $addr_list_ref = $_->{addr_list};
    
    print "  target=$target priority=$priority weight=$weight port=$port addresses=";
    {
	$, = ",";
	print @$addr_list_ref;
    }
    print "\n";
}

