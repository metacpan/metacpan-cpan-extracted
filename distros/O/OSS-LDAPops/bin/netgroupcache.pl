#!/usr/bin/perl

=head1 NAME

netgroupcache.pl - a programme to make a local cache of LDAP netgroups. 

=head1 SYNOPSIS

This programme pulls a copy of netgroups from the LDAP server, prefixes their name with 'local'
and places them in the /etc/netgroups file

by doing this, you can configure access.conf to also allow these local netgroups. thus
allowing login even if the LDAP server is not online to answer netgroup queries. 

This script should be run from cron at an appropriate interval.

=head1 CONFIG

A configuration file is required in /etc/netgroupcache.conf An example is below:

	#Global config
	#These options are passed to OSS::LDAPops and are all required.
	$GLOBAL::config = 
	{
		LDAPHOST	=>	'ldap01.mydomain.net',
		BINDDN		=>	'uid=webportal, ou=writeaccess, dc=auth, dc=mydomain,dc=net',
		BASEDN		=> 	'dc=auth,dc=mydomain,dc=net',
		NISDOMAIN	=>	'auth.mydomain.net',
		PASSWORD	=>	'xyzzy'

	};

	#This 1 is required!
	1;

This example is also included in the source distribution. 

=head USAGE

netgroupcache.pl <netgroup> <netgroup> <netgroup> .....

\* may be used as a wildcard, including as the only argument
to get all netgroups.

(you can add as many netgroups as you like)

This code uses OSS::LDAPops Please see the OSS::LDAPops manual for more details.

=cut


#use strict pragma.
use strict;

#Use OSS::LDAPops object. 
use OSS::LDAPops;

#Load config
require '/etc/netgroupcache.conf';


#Instantiate new object. 
my($ldapopsobj) = OSS::LDAPops->new($GLOBAL::config);
if (ref($ldapopsobj) !~ m/OSS::LDAPops/ ) {die("Error instantiating object: $ldapopsobj")}; 
my($ret);
my(@retu);

#Get netgroup entries
sub get_entries
{
	my(@out);
	my($ngref);
	$ldapopsobj->bind;
	foreach my $netgroup (@ARGV)
	{
		@retu = $ldapopsobj->searchnetgroup($netgroup);
		die($retu[0]) if (($retu[0] ne undef) and (ref($retu[0]) !~ m/Net::LDAP::Entry/) );
		foreach my $entry (@retu) 
		{
			$ngref = $entry->get_value('nisNetgroupTriple', asref => 1);
			foreach my $ngt (@$ngref)
			{
				push(@out, 'local'.$entry->get_value('cn').' '.$ngt."\n"); 
			};
		};
	};
	return(@out);
};

#Write output to /etc/netgroup
sub write_output
{
	my(@file) = @_;
	open(FILE, '>'.'/etc/netgroup') or die($!);
	print(FILE @file);
	close(@file);

};

&write_output(&get_entries);
