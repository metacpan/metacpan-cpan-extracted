#!/usr/bin/perl
use Net::FileShare;

my $dir = `echo \$HOME`; chomp($dir);
my ($fh) = new Net::FileShare(
	_directory => $dir,
	_debug	   => '1');

	$fh->client_automated("127.0.0.1","3000","list");
	
		
		
		
		
		
