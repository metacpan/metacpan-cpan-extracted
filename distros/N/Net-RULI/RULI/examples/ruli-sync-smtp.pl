#! /usr/bin/perl -w
#
# $Id: ruli-sync-smtp.pl,v 1.3 2004/09/24 19:40:49 evertonm Exp $

use strict;
use Net::RULI;

if ($#ARGV != 0) {
    die <<__EOF__;
usage:   $0 domain

example: $0 gnu.org
__EOF__
}

my ($domain) = @ARGV;

my $srv_list_ref = Net::RULI::ruli_sync_smtp_query($domain, 0);
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

