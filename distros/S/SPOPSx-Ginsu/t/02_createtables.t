#!/usr/bin/perl -w

BEGIN {
	use lib qw( t );
}

use strict;
use Test::More tests => 1;
use DBI;

use my_dbi_conf;
use test_config;
test_config->recreate_tables;

ok( 1, 'recreate_tables' );

1;
