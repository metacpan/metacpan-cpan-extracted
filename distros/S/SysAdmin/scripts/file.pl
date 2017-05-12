#!/usr/local/bin/perl
use strict;

use SysAdmin::File;

my $object = new SysAdmin::File(name => "/tmp/test_file.txt");

## Write data to file
my @write_to_file = ("First data written using writeFile\n");

$object->writeFile(\@write_to_file);



## Read data
my $array_ref = $object->readFile();

foreach my $row(@$array_ref){
	print "First Read - $row\n";
}



## Write data to file
my @append_to_file = ("Second data written using appendFile\n");

$object->appendFile(\@append_to_file);



## Read append data
my $second_array_ref = $object->readFile();

foreach my $row(@$second_array_ref){
	print "Second Read - $row\n";
}
