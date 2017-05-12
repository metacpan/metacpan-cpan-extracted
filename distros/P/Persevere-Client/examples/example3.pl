#!/usr/bin/perl
use warnings;
use strict;
use Persevere::Client;
use JSON::XS;

my $testClassName = "TestClass";

my $json = JSON::XS->new->ascii->shrink->allow_nonref;
my $persvr = Persevere::Client->new(
	host => "localhost", 
	port => "8080", 
	auth_type => "none",
#	auth_type => "basic", 
#	username => "test", 
#	password => "pass", 
	debug => 0
);

die "Unable to connect to $persvr->{uri}\n" if !($persvr->testConnection);

my $status;
my $statusreq = $persvr->serverInfo;
if ($statusreq->{success}){
	$status = $statusreq->{data};
	print "VM: $status->{vm}\nVersion: $status->{version}\n";
}
print "Class File Exists\n" if $persvr->classExists("File");
print "Class Garbage Doesn't Exist\n" if (!($persvr->classExists("garbage")));

my @class_list;
my $classreq = $persvr->listClassNames;
if ($classreq->{success}){
	@class_list = @{$classreq->{data}};
}

print $json->encode(\@class_list) . "\n";
