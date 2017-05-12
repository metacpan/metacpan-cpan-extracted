#!/usr/bin/perl

# Test ORLite's behaviour when the SQLite file is broken

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 2;
use Test::Script;
use File::Remove;
use t::lib::Test;

# Where the test file will be
my $file = test_db();
ok( ! -f $file, 'File does not exist' );

# Corrupt the database file
open( FILE, '>', $file ) or die("open: $!");
print FILE "broken" or die("print: $!");
close FILE          or die("close: $!");

# Try to load the database
eval <<'END_PERL';
package Foo;

use ORLite {
	file  => $file,
	prune => 1,
};

1;
END_PERL
ok( $@, 'Loading a bad database throws an exception' );
