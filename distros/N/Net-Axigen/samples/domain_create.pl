# ****************************************************************
# Net::Axigen
# Create domain, set quotas of the domain
# ****************************************************************
# Copyright (c) Alexandre Frolov, 2009
# alexandre@frolov.pp.ru  
# http://www.shop2you.ru
# ****************************************************************

use strict;
use Net::Axigen;

require 'io_exception_dbg.pl';

eval
{
	print "Net::Axigen sample. Creation of the new domain, set quotas of the domain\n\n";
	
	print 'Host: '; my $host=<STDIN>; chomp($host);
	print 'Port: '; my $port=<STDIN>; chomp($port);
	print 'Axigen admin password: '; my $password=<STDIN>; chomp($password);
	
	my $axi = Net::Axigen->new($host, $port, 'admin', $password, 10);
	$axi->connect();

	# Print Axigen Mail Server and OS Version
	my ($version_major, $version_minor, $version_revision)=$axi->get_version();
	my ($os_version_full, $os_name, $os_version_platform)=$axi->get_os_version();
	print "\n\nAxigen Version: ".$version_major.'.'.$version_minor.'.'.$version_revision.", OS: ".$os_version_full."\n";

	# Printing of the current list of domains
	my $domain_list = $axi->listDomains();
	
	print "Current list of domains:\n";
	print "------------\n";
	foreach my $ptr(@$domain_list) { print "$ptr\n"; }
	print "------------\n\n";	

	print 'New Domain: '; my $domain=<STDIN>; chomp($domain);
	print "Domain $domain postmaster password: "; my $pmpass=<STDIN>; chomp($pmpass);
	print	'Messages files storage limit (1-128 files on 256 Mbyte): '; my $files=<STDIN>; chomp($files);

	print "\nCreate domain $domain with postmaster password $pmpass and limit $files storage files? (yes/no)";
	my $create=<STDIN>; chomp($create);
	
	if($create eq 'yes')
	{
		# Creation of the new domain
		$axi->createDomain($domain, $pmpass, $files);

		# Set most important quotas for the domain
		my $q = 
		{ 
			maxAccounts => 10, # admin limits
			maxAccountMessageSizeQuota => 200000, # admin limits
			maxPublicFolderMessageSizeQuota => 300000, # admin limits
			messageSize => 20000, # domain quota
			totalMessageSize => 200000 # domain quota
		};
		$axi->setDomainQuotas($domain, $q);
		
		# Printing of the new list of domains with the information on domains
		my $domain_info = $axi->listDomainsEx();
		
		print "\nNew list of domains:\n";
		print "------------\n";
		print "Domain \t\tUsed\tTotal\n";
		foreach my $domain( sort keys %$domain_info) 
		{
			print "$domain:\t".$domain_info->{ $domain }->{used}."\t".$domain_info->{ $domain }->{total}."\n"; 
		}
		print "------------\n";
	}
	
	my $ok=$axi->close();
	print 'End: '."$ok\n";
};
io_exception_dbg->catch($@);