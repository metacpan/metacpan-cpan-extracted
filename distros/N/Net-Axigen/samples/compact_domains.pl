# ****************************************************************
# Net::Axigen
# Compact domains
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
	print "Net::Axigen sample. Compact domains\n\n";
	
	print 'Host: '; my $host=<STDIN>; chomp($host);
	print 'Port: '; my $port=<STDIN>; chomp($port);
	print 'Axigen admin password: '; my $password=<STDIN>; chomp($password);
	
	my $axi = Net::Axigen->new($host, $port, 'admin', $password, 600); # set big timeout
	$axi->connect();

	# Print Axigen Mail Server and OS Version
	my ($version_major, $version_minor, $version_revision)=$axi->get_version();
	my ($os_version_full, $os_name, $os_version_platform)=$axi->get_os_version();
	print "\n\nAxigen Version: ".$version_major.'.'.$version_minor.'.'.$version_revision.", OS: ".$os_version_full."\n";

	# Printing of the new list of domains with the information on domains
	my $domain_info = $axi->listDomainsEx();
	
	print "List of domains before compacting:\n";
	print "------------\n";
	print "Domain \t\tUsed\tTotal\n";
	foreach my $domain( sort keys %$domain_info) 
	{
		print "$domain:\t".$domain_info->{ $domain }->{used}."\t".$domain_info->{ $domain }->{total}."\n"; 
	}
	print "------------\n";

	# Default compacting
	$axi->compactAllDomains();

	# Force compacting
	#$axi->compactAllDomains(1);

	# Printing of the new list of domains with the information on domains
	my $domain_info = $axi->listDomainsEx();
	
	print "\nList of domains after compacting:\n";
	print "------------\n";
	print "Domain \t\tUsed\tTotal\n";
	foreach my $domain( sort keys %$domain_info) 
	{
		print "$domain:\t".$domain_info->{ $domain }->{used}."\t".$domain_info->{ $domain }->{total}."\n"; 
	}
	print "------------\n";
	
	my $ok=$axi->close();
	print 'End: '."$ok\n";
};
io_exception_dbg->catch($@);