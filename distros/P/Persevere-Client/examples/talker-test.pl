#!/usr/bin/perl
use warnings;
use strict;
use Persevere::Client;
use JSON::XS;
use Data::Dumper;
use HTTP::Headers;
use Time::HiRes qw(usleep);

my $json = JSON::XS->new;

my $persvr = Persevere::Client->new(
		host => "localhost",
		port => "8080",
		auth_type => "none",
#	auth_type => "basic",
#	username => "test",
#	password => "pass",
		debug => 1,
		defaultSourceClass => "org.persvr.datasource.InMemorySource",
#		base_uri => "activetalker"
		);

# createObjects requires an array of hashes, so push your objects (hashes) onto an array

my $className = "Conference";
my $initialclass = $persvr->class($className);

while (1){
my $datareq = $initialclass->query();
# TODO are there timeout issues with apache/comet config?

if ($datareq->{success}){
	my @data = @{$datareq->{data}};
	my @new_data;
	my $data;
	foreach my $item (@data){
		if ($item->{talking}){
			$data = 0;
		}else{
			$data = 1;
		}
#		print "ID: " . $item->{id} . "\n";
		my $propset = $initialclass->propSet("$item->{id}.talking", $data);
		if ($propset->{code} != 200){
			warn "error updating $item->{id}.talking";
		}
#		sleep 1;
	}
}
sleep 1;
}
