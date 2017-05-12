#!/usr/bin/perl

=head1 NAME

client.pl - example Tacacs+ client

=head1 SYNOPSIS

	client.pl
		--username
		--password
		--key
		--server
		--port      (optional) default 49

	#example
	client.pl --username USER --password PASS --key SECRET --server OUR.TACACS.SERVER

=head1 DESCRIPTION

Simple example pap auth client.

=cut


use strict;
use warnings;

use FindBin;
use lib $FindBin::Bin.'/../lib';

use Net::TacacsPlus::Constants;
use Net::TacacsPlus qw{ tacacs_client };

use Getopt::Long;
use Pod::Usage;

use English;


exit main();

sub main {
	
	my $username;
	my $password;
	my $key;
	my $server;
	my $port = 49;
	
	GetOptions(
		'username=s' => \$username,
		'password=s' => \$password,
		'key=s'      => \$key,
		'server=s'   => \$server,
		'port=s'     => \$port,
	) or pod2usage(2);
	pod2usage(2) if (!$username or !$password or !$key or !$server);
	
	my $client = tacacs_client(
		'host' => $server,
		'port' => $port,
		'key'  => $key,
	);
	
	if ($client->authenticate($username, $password, TAC_PLUS_AUTHEN_TYPE_PAP)){                   
		print "Authentication successful.\n";                                  
	} else {                                                    
		print "Authentication failed: ".$client->errmsg()."\n";         
	}                                                           
	
	return 0;
}




