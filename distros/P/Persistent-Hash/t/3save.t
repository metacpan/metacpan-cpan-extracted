#!/usr/bin/perl
do { print "1..0\n"; exit; } if (not -e 't/config.pl');

use strict;
use Test;
plan tests => 1;


use Persistent::Hash::TestHash;

my $config = LoadConfig();

$Persistent::Hash::Tests::DSN = $config->{dsn};
$Persistent::Hash::Tests::DB_USER = $config->{dbuser};
$Persistent::Hash::Tests::DB_PW = $config->{dbpw};
$Persistent::Hash::Tests::STORAGE_MODULE = $config->{storage_module};

my $test_hash = Persistent::Hash::TestHash->new();

$test_hash->{tk1} = 25;
$test_hash->{tk2} = 30;
$test_hash->{tk3} = 'test!';
$test_hash->{itk1} = 'testing';
$test_hash->{itk2} = 'persistent';
$test_hash->{itk3} = 'hash!';

my $id = $test_hash->Save();

if($id == 1)
{
	ok(1);
}
else
{
	ok(0);
}


sub LoadConfig
{
	my $config;
	open(CONF, "t/config.pl") || &creve("Could not open t/config.pl");
	while(<CONF>) { $config .= $_; }
	close CONF;
	$config = eval $config;
	if($@)
	{
        	&creve($@);
	}

	return $config;
}


sub creve
{
        my $msg = shift;

        print "$msg\n";

        print "\nSomething is wrong.\n";
        print "Please contact the author.\n";
        print "not ok 1\n";
        exit;
}
