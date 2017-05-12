#!/usr/local/bin/perl -w
# read a key from a SimpleCDB

use strict;

use SimpleCDB;	# exports as per Fcntl

my $k = shift or die "usage: $0 <key>\n";

$| = 1;

$SimpleCDB::DEBUG = $ENV{SIMPLECDBDEBUG};

my %h;
my $h;
$h = tie %h, 'SimpleCDB', 'db', O_RDONLY;

unless ($h)
{
	if ($! == POSIX::EWOULDBLOCK)
	{
		print "DB is busy, please try again later...\n";
		exit 2;
	}
	else
	{
		die "tie failed: $SimpleCDB::ERROR\n";
	}
}

my $v = exists $h{$k};
die "exists: $SimpleCDB::ERROR" if $SimpleCDB::ERROR;

if ($v)
{
	print "[$k] = [$h{$k}]\n";
	die "fetch: $SimpleCDB::ERROR" if $SimpleCDB::ERROR;
	exit 0;
}
else
{
	print "[$k] not found\n";
	exit 1;
}
