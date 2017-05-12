#! /usr/bin/perl -w
#
# $Id: ruli-sync-srv.pl,v 1.3 2004/09/24 19:40:49 evertonm Exp $

use strict;
use Net::RULI;

if ($#ARGV != 1) {
    die <<__EOF__;
usage:   $0 service domain

example: $0 _http._tcp gnu.org
__EOF__
}

my ($service, $domain) = @ARGV;

my $srv_list_ref = Net::RULI::ruli_sync_query($service, $domain, -1, 0);
if (!defined($srv_list_ref)) {
    warn "$service.$domain query failed\n";
    exit(1);
}

print "$service.$domain\n";

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

