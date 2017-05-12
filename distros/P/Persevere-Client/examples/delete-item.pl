#!/usr/bin/perl
use warnings;
use strict;
use Persevere::Client;
use JSON::XS;

# Create, Update, Delete Example

my $json = JSON::XS->new;

my $persvr = Persevere::Client->new(
	host => "localhost",
	port => "7080",
	auth_type => "none",
#	auth_type => "basic",
#	username => "test",
#	password => "pass",
	debug => 1,
	defaultSourceClass => "org.persvr.datasource.InMemorySource"
);


my $className = "test";
my $initialclass = $persvr->class($className);
print "Class: " . $initialclass->fullname . "\n";

if ($initialclass->exists){
	my $outcome = $initialclass->deleteById("testItem");
	if (!($outcome->{success})){
		print "Unable to delete item.\n";
	}
}
