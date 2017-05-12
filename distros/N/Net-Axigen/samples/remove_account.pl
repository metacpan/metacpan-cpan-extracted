# ****************************************************************
# Net::Axigen
# Remove account from the domain
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
	print "Net::Axigen sample. Remove account from the domain.\n\n";
	
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
	
	print "List of domains:\n";
	print "------------\n";
	foreach my $ptr(@$domain_list) { print "$ptr\n"; }
	print "------------\n\n";	

	print 'The domain from which the account will be removed: '; my $domain=<STDIN>; chomp($domain);

	# Print current account list
	my $account_list = $axi->listAccounts($domain);
	print "\nCurrent account list\n";
	print "------------\n";
	foreach my $ptr(@$account_list) { print "$ptr\n"; }
	print "------------\n";	

	print 'Removed account: '; my $acc=<STDIN>; chomp($acc);
	print "\nRemove account $acc".'@'."$domain? (yes/no)";
	my $rm=<STDIN>; chomp($rm);
	
	if($rm eq 'yes')
	{
		# Remove of the new account
		$axi->removeAccount($domain, $acc);

		# Print new account list
		my $account_list = $axi->listAccounts($domain);
		print "\nNew account list\n";
		print "------------\n";
		foreach my $ptr(@$account_list) { print "$ptr\n"; }
		print "------------\n";	
	}
	
	my $ok=$axi->close();
	print 'End: '."$ok\n";
};
io_exception_dbg->catch($@);