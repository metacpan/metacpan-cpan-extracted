#!/usr/bin/env perl 

use 5.8.0;
use strict;
use warnings;

use Data::Dumper;

use NetSDS::Class::Abstract;

my $obj = NetSDS::Class::Abstract->new(
	zuka => '123',
	buka => 'sdfsdf',
);

print Dumper($obj);

print "Serializing... ";

my $ser = $obj->serialize();
my $new = NetSDS::Class::Abstract->deserialize($ser);

print "done\n";

print Dumper($new);

#$obj->nstore("/tmp/_tmp_obj.stor" );

1;
