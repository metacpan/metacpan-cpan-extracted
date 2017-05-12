#!/usr/bin/perl

use MyMailReceiver;

use Carp;
use Carp qw(verbose);

usage() unless @ARGV;

while (@ARGV) {
	$a = shift(@ARGV);

	if ($a eq '-server') {
		$server = shift(@ARGV);
	} elsif ($a eq '-bp') {
		$showqueue = 1;
	} elsif ($a eq '-q') {
		$runqueue = 1;
	} elsif ($a eq '-port') {
		$port = shift(@ARGV);
	} else {
		usage();
	}
}

unless (-t STDERR) {
	close(STDOUT);
	close(STDERR);
	close(STDIN);
}

MailReceiver->showqueue()
	if $showqueue;

MailReceiver->runqueue()
	if $runqueue;

MailReceiver->server('IpAddr' => $server, 'Port' => $port)
	if $server;

exit(0);

sub usage
{
	print <<END;
$0: Usage:
	-server %1  	- start a server using IP address %1 
	-port %1  	- use port %1 
	-bp		- show the queue
	-q		- run the queue
END
	exit(1);
}


