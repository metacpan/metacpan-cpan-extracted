#!perl
use strict;
use SNMP::Extension::PassPersist;

# create the object
my $extsnmp = SNMP::Extension::PassPersist->new;

# add a few OID entries
$extsnmp->add_oid_entry(".1.2.42.1", "integer", 42);
$extsnmp->add_oid_entry(".1.2.42.2", "string" , "the answer");

# run the program
$extsnmp->run;
