#!/usr/bin/perl

use warnings;
use strict;
use Persevere::Client;
use JSON::XS;
use Data::Dumper;

# Enforced schema example

my $json = JSON::XS->new->ascii->shrink->allow_nonref;

my $persvr = Persevere::Client->new(
	host => "localhost",
	port => "8080",
	auth_type => "none",
#	auth_type => "basic",
#	username => "test",
#	password => "pass",
	defaultSourceClass => "org.persvr.datasource.InMemorySource",
	debug => "1"
);

my $dataname = "TestStore";
# uuid uses strings instead of integer's for the id field
my $test = $persvr->class($dataname)->uuid;
$test->properties(
	'value' => {'index' => $json->true, 'optional' => $json->false, 'type' => 'string'},
	'position' => {'index' => $json->true, 'optional' => $json->true, 'type' => 'integer'},
);
#my $test = $persvr->class($dataname)->uuid;
if (!($test->exists)){
	print "Creating Class: " . $test->fullname . "\n";
	my $result = $test->create;
	if ($result->{success}){
		print "successfully created " . $test->fullname . " class\n";
	}
}else{
	print "Class " . $test->fullname . " already exists\n";
}

# This example uses uuid's to store values, so they must be strings, and an id must be set
my %h1 = (id => "item1", value => "test1", position => 11);
my %h2 = (id => "item2", value => "test1", position => 21);
my %h3 = (id => "item3", value => "test2", position => 31);
my %h4 = (id => "item4", value => "test2", position => 41);

my @values = (\%h1, \%h2, \%h3, \%h4);

my $result = $test->updateObjects(\@values);
if ($result->{success}){
	print "Updated: " . $test->fullname . "\n";
	print $test->{content} . "\n";
}else{
	print "Failed to update " . $test->fullname . "\n";
}

my $query = $test->query("?value=\"test1\"");
if ($query->{success}){
	my @data = @{$query->{data}};
	print $json->pretty->encode(\@data) . "\n";
}else{
	print "Error preforming querry\n";
}

# this should fail
my %baddata = (id => "item5", position => "5");
my @post = (\%baddata);
my $badr = $test->updateObjects(\@post);
if ($result->{success}){
	print "Updated: " . $test->fullname . "\n";
	print $test->{content} . "\n";
}else{
	print "Failed to update " . $test->fullname . "\n";
	print $test->{content} . "\n";
}
