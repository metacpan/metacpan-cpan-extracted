#!/usr/local/bin/perl -w
# iterate over a SimpleCDB

use strict;

use SimpleCDB;	# exports as per Fcntl

my $re = shift;

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

my ($k, $v);
while (($k, $v) = each %h)
{
	die "each: $SimpleCDB::ERROR" if $SimpleCDB::ERROR;
	print '' . (defined $k ? "[$k]" : '<undef>') . " = " . 
		(defined $v ? "[$v]" : '<undef>') . "\n" 
		if (not defined $re or $k =~ /$re/);
}

undef $h;
untie %h;
