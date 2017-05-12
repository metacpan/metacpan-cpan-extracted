#!/usr/bin/perl

# Test the { prune => 1 } feature of ORLite

use strict;

BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 7;
use Test::Script;
use File::Remove;
use t::lib::Test;

# Where the test file will be
my $file = test_db();
ok( ! -f $file, 'File does not exist' );

# Run the test program WITHOUT prune
script_runs( [
	't/08_prune.pl',
	file   => $file,
	create => 1,
], '08_prune.pl without prune ran ok' );
ok( -f $file, '08_prune.pl without prune created the file as expected' );

# Clean up
ok( File::Remove::remove($file), 'Removed the test file' );
ok( ! -f $file, 'Removed test file' );

# Run the test program again WITH prune
script_runs( [
	't/08_prune.pl',
	file   => $file,
	create => 1,
	prune  => 1,
], '08_prune.pl with prune ran ok' );
ok( ! -f $file, '08_prune.pl with prune removed the file' );
