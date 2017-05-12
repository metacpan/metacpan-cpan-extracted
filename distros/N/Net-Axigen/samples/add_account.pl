# ****************************************************************
# Net::Axigen
# Add account in the domain. Set account data.
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
	print "Net::Axigen sample. Add account in the domain. Set account data.\n\n";
	
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

	print 'The domain in which the account will be added: '; my $domain=<STDIN>; chomp($domain);

	# Print current account list
	my $account_list = $axi->listAccounts($domain);
	print "\nCurrent account list\n";
	print "------------\n";
	foreach my $ptr(@$account_list) { print "$ptr\n"; }
	print "------------\n";	

	print 'New account: '; my $acc=<STDIN>; chomp($acc);
	print 'Account password: '; my $accpassword=<STDIN>; chomp($accpassword);

	print "\nCreate account $acc".'@'."$domain with password $accpassword? (yes/no)";
	my $create=<STDIN>; chomp($create);
	
	if($create eq 'yes')
	{
		# Creation of the new account
		$axi->addAccount($domain, $acc, $accpassword);

		# Set utf-8 convertor locale to use Russian (default)
		$axi->{ locale } = 'windows-1251';
		
		# Set First Name and Last Name
		$axi->setAccountContactData($domain, $acc, "Александр", "Фролов");
	
		# Set subject and content of the quota limit notification 
		my $quota_subject='ВНИМАНИЕ! Скоро будет исчерпаны квоты на почтовый ящик (%3.3p% из %SKb и %3.3q% из %C сообщений)';
		my $quota_msg='Здравствуйте, %N'."\n\n";
		$quota_msg=$quota_msg.'Ваш почтовый ящик %A@%D скоро переполнится:'."\n";
		$quota_msg=$quota_msg.'общий размер сообщений: %sKb (предел %SKb);'."\n";
		$quota_msg=$quota_msg.'количество сообщений: %c (предел %C)'."\n\n";
		$quota_msg=$quota_msg.'Если почтовый ящик переполнится, Вы не сможете больше получать сообщения. ';
		$quota_msg=$quota_msg.'Чтобы этого избежать, пожалуйста удалите часть сообщений.'."\n\n";
		$quota_msg=$quota_msg.'С уважением, Администрация.'."\n";
	
		$axi->setQuotaLimitNotification($domain, $acc, $quota_subject, $quota_msg);
	
		# Set account password (use it to change password)
		$axi->setAccountPassword($domain, $acc, $accpassword);

		# Set Russian language for the WebMail user interface
		$axi->setAccountWebMailLanguage($domain, $acc, 'ru');
		
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