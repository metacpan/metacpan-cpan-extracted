# ****************************************************************
# Net::Axigen
# Register domain
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
	print "Net::Axigen sample. Register domain\n\n";
	
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

	print 'Registered Domain: '; my $domain=<STDIN>; chomp($domain);

	print "\nRegister  domain $domain? (yes/no)";
	my $unreg=<STDIN>; chomp($unreg);
	
	if($unreg eq 'yes')
	{
		# Register domain
		$axi->registerDomain($domain);
		
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