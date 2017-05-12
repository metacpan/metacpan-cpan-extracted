#!/usr/bin/perl
do { print "1..0\n"; exit; } if (not -e 't/config.pl');

use strict;
use Test;
plan tests => 784;


use Persistent::Hash::TestHash;

my $config = LoadConfig();

$Persistent::Hash::Tests::DSN = $config->{dsn};
$Persistent::Hash::Tests::DB_USER = $config->{dbuser};
$Persistent::Hash::Tests::DB_PW = $config->{dbpw};
$Persistent::Hash::Tests::STORAGE_MODULE = $config->{storage_module};


for(3..100)
{
	my $test_hash = Persistent::Hash::TestHash->new();

	$test_hash->{tk1} = 25;
	$test_hash->{tk2} = 30;
	$test_hash->{tk3} = 'test!';
	$test_hash->{itk1} = 'testing';
	$test_hash->{itk2} = 'persistent';
	$test_hash->{itk3} = 'hash (load)!';

	my $id = $test_hash->Save();

	if($id == $_)
	{
		ok(1);
		TestOneHash($id);
	}
	else
	{
		ok(0);
	}
}


sub TestOneHash
{
	my $id = shift;
	my $reloaded = Persistent::Hash::TestHash->load($id);
	if(defined $reloaded)
	{
		ok(1);
	}
	else
	{
		ok(0);
	}
	if($reloaded->{tk1} == 25) { ok(1) }  else { ok(0); }
	if($reloaded->{tk2} == 30) { ok(1) }  else { ok(0); }
	if($reloaded->{tk3} eq 'test!') { ok(1) }  else { ok(0); }
	if($reloaded->{itk1} eq 'testing') { ok(1) }  else { ok(0); }
	if($reloaded->{itk2} eq 'persistent') { ok(1) }  else { ok(0); }
	if($reloaded->{itk3} eq 'hash (load)!') { ok(1) }  else { ok(0); }
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
