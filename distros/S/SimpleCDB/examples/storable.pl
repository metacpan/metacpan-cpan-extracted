#!/usr/bin/perl -w

use strict;

use Storable;

use SimpleCDB;	# exports as per Fcntl

my %h;

$SimpleCDB::DEBUG = 10;

tie %h, 'SimpleCDB', 'db', O_WRONLY or die "tie failed: $@\n";

$h{"hello"} = "there";

$h{'complex'} = Storable::freeze({a => 2, x=>'y'});

untie %h;

tie %h, 'SimpleCDB', 'db', O_RDONLY or die "tie failed: $@\n";

print "get: ", $h{"hello"}, "\n";
