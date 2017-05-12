#! /usr/bin/perl

use strict;
use Net::DNS::DurableDNS;
use DNS::ZoneParse;
use Data::Dumper;

# This example looks for A records in all zones with a specific IP and changes them to another IP

my $apiuser = 'xyz';
my $apikey = 'abc';

my $old_ip = '184.106.219.186';
my $new_ip = '198.101.129.155';

# set up a new api connection
my $durable = Net::DNS::DurableDNS->new({apiuser => $apiuser, 
                                         apikey => $apikey});

my $zones = $durable->listZones();

foreach my $zone (@$zones) {
        
    my $records = $durable->listRecords({zonename=>$zone});
    
    foreach my $record (@$records) {
        
        print $record->{id} . '  ' . $record->{name} . '  ' . $record->{type} . '  ' . $record->{data} . "\n";
        
        if ($record->{data} eq $old_ip && $record->{type} eq 'A') {
            warn("Updating " . $record->{name} . "\n");
            my $update = $durable->updateRecord({zonename=>$zone,
                                        name=>$record->{name},
                                        ttl=>'3600',
                                        type=>'A',
                                        data=>$new_ip,
                                        orcreate=>0});
        
        }
        
    
    }    

}


exit;
