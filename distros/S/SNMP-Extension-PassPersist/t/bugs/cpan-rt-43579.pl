#!/usr/bin/perl
use strict;
use warnings;
use SNMP::Extension::PassPersist;


my $extsnmp = SNMP::Extension::PassPersist->new(
    backend_collect => \&update_tree,
    idle_count      => 10,      # no more than 10 idle cycles
    refresh         => 10,      # refresh every 10 sec
);

my $oid = ".1.3.6.1.4.1.2021.51.";

sub update_tree {
    $extsnmp->add_oid_entry($oid."1",   "string", "TEST");
    $extsnmp->add_oid_entry($oid."2.1", "string", "2.1");
    $extsnmp->add_oid_entry($oid."2.2", "string", "2.2");
    $extsnmp->add_oid_entry($oid."4",   "integer", 1);
}

# run the program
$extsnmp->run;

