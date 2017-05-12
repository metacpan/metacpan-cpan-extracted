#!/usr/local/bin/perl
use strict;

use SysAdmin::SNMP;

my $sysName = '.1.3.6.1.2.1.1.5.0';
my $ifDescr = '.1.3.6.1.2.1.2.2.1.2';

my $object = new SysAdmin::SNMP(ip        =>"localhost",
                                community => "public");

my $snmp_string = $object->snmpget($sysName);
my $snmp_hash_ref = $object->snmpwalk($ifDescr);

print "SNMP String $snmp_string\n";

foreach my $key ( sort keys %$snmp_hash_ref){
	
	my $value = $$snmp_hash_ref{$key};
	print "Key $key, Value $value\n";
}

print "All Interfaces\n";

my $fetch_interfaces_hash_ref = $object->fetchInterfaces();

foreach my $key ( sort keys %$fetch_interfaces_hash_ref){
	
	
	my $ifIndex = $$fetch_interfaces_hash_ref{$key}{'ifIndex'};
	my $ifDescr = $$fetch_interfaces_hash_ref{$key}{'ifDescr'};
	my $ifType = $$fetch_interfaces_hash_ref{$key}{'ifType'};
	my $ifType_name = $$fetch_interfaces_hash_ref{$key}{'ifType_name'};
	my $ifAdminStatus = $$fetch_interfaces_hash_ref{$key}{'ifAdminStatus'};
	my $ifOperStatus = $$fetch_interfaces_hash_ref{$key}{'ifOperStatus'};
	my $ifAlias = $$fetch_interfaces_hash_ref{$key}{'ifAlias'};
	
	print "ifIndex $ifIndex | ifDescr $ifDescr | ifType $ifType | ifType_name $ifType_name | ifAdminStatus $ifAdminStatus | ifOperStatus $ifOperStatus | ifAlias $ifAlias\n";
}


print "Active Interfaces\n";

my $fetch_active_interfaces_hash_ref = $object->fetchActiveInterfaces();

foreach my $key ( sort keys %$fetch_active_interfaces_hash_ref){
	
	my $ifIndex = $$fetch_active_interfaces_hash_ref{$key}{'ifIndex'};
	my $ifDescr = $$fetch_active_interfaces_hash_ref{$key}{'ifDescr'};
	my $ifType = $$fetch_active_interfaces_hash_ref{$key}{'ifType'};
	my $ifType_name = $$fetch_active_interfaces_hash_ref{$key}{'ifType_name'};
	my $ifAdminStatus = $$fetch_active_interfaces_hash_ref{$key}{'ifAdminStatus'};
	my $ifOperStatus = $$fetch_active_interfaces_hash_ref{$key}{'ifOperStatus'};
	my $ifAlias = $$fetch_active_interfaces_hash_ref{$key}{'ifAlias'};
	
	print "ifIndex $ifIndex | ifDescr $ifDescr | ifType $ifType | ifType_name $ifType_name | ifAdminStatus $ifAdminStatus | ifOperStatus $ifOperStatus | ifAlias $ifAlias\n";
}
