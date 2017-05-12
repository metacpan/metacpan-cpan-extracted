#!/usr/bin/perl
use Net::FileShare;

my $dir = `echo \$HOME`; chomp($dir);
my ($fh) = new Net::FileShare(
	_send_only => '1',
	_directory => $dir,
	_debug	   => '1');

	$fh->server_connection;	
		
		
		
		
		
