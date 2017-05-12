#!/usr/bin/perl

if ( !$ARGV[1] || !$ARGV[0] ) {
   print "Suplly two arguments:\n";
   print "$0 <address> <community>\n";
   exit 2;
}

use SNMP::BridgeQuery;
#use SNMP::BridgeQuery qw(querymacs queryports queryat);

$fdb = queryfdb(host => $ARGV[0],
                comm => $ARGV[1]);

%hash = %{$fdb};

print "MAC Address  -> Switch Port \n";
print "$_ -> $hash{$_}\n" foreach (keys %hash);


