#!/usr/bin/perl
use strict;
use Net::TFTPd 0.05 qw(%OPCODES);

# change ROOTDIR to your TFTP root directory
my $rootdir = $ARGV[0];

unless(-d $rootdir)
{
	print "\nUsage: simpleTFTPd.pl path/to/rootdir\n\n";
	exit 1;
}

# callback sub used to print transfer status
sub callback
{
	my $req = shift;
	if($req->{'_REQUEST_'}{'OPCODE'} eq $OPCODES{'RRQ'})
	{
		# RRQ
		printf "block: %u\/%u\n", $req->{'_REQUEST_'}{'LASTACK'}, $req->{'_REQUEST_'}{'LASTBLK'};
	}
	elsif($req->{'_REQUEST_'}{'OPCODE'} eq $OPCODES{'WRQ'})
	{
		# WRQ
		printf "block: %u\/%u\n", $req->{'_REQUEST_'}{'LASTBLK'}, $req->{'_REQUEST_'}{'LASTACK'};
	}
}

# create the listener
my $listener = Net::TFTPd->new('RootDir' => $rootdir, 'Writable' => 1, 'Timeout' => 10, 'CallBack' => \&callback) or die Net::TFTPd->error;
printf "TFTP listener is bound to %s:%d\nTFTP listener is waiting %d seconds for a request\n", $listener->{'LocalAddr'} ? $listener->{'LocalAddr'} : "'any address'",  $listener->{'LocalPort'}, $listener->{'Timeout'};

# wait for any request (RRQ or WRQ)
if(my $request = $listener->waitRQ())
{
	# received request
	printf "Received a %s for file '%s'\n", $OPCODES{$request->{'_REQUEST_'}{'OPCODE'}}, $request->getFileName();

	# process the request
	if($request->processRQ())
	{
		printf "OK, transfer completed successfully for file %s, %u bytes transferred\n", $request->getFileName(), $request->getTotalBytes();
	}
	else
	{
		die Net::TFTPd->error;
	}
}
else
{
	# request not received (timed out waiting for request etc.)
	die Net::TFTPd->error;
}
