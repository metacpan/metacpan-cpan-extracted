#!/usr/bin/perl -w
use strict;

use my_dbi_conf;
use MyDBI;

## get database connection
my $db = MyDBI->global_datasource_handle;

## load SQL from file
open(SQL, "t/example.sql") or die "$@";

my $sql = join '', <SQL>;
my @inserts = split(";\n", $sql);

foreach my $insert (@inserts) {
	$db->do($insert);
}

1;