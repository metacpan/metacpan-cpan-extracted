#!/usr/bin/perl -w

BEGIN {
	use lib qw( t );
}

use strict;
use Test::More tests => 14;

use my_dbi_conf;
use test_config;
test_config->recreate_tables;
require 'fill_tables.pl';

my ($h, $s);

##-----  single inheritance remove  -----
my $t = 'remove obj w/single inheritance';
ok( $h = Helicopter->fetch(8), $t);
ok( $h->remove, $t);

## check tables to make sure it's gone
foreach my $class ( qw(Helicopter Aircraft Vehicle MyBaseObject) ) {
	my $args = {	from => [ $class->base_table ],
					select => [ 'count(*)'],
					where => $class->id_clause(8, undef, undef),
					return => 'single'
				};
	my $row = eval { $class->db_select($args);	};
	is( $row->[0], 0, $t . ', gone from table: ' . $class->base_table );
}

##-----  multiple inheritance remove  -----
$t = 'remove obj w/multiple inheritance';
ok( $s = Seaplane->fetch(12), $t);
ok( $s->remove, $t );

## check tables to make sure it's gone
foreach my $class ( qw(Seaplane FixedWing Aircraft Vehicle Boat MyBaseObject) ) {
	my $args = {	from => [ $class->base_table ],
					select => [ 'COUNT(*)'],
					where => $class->id_clause(12, undef, undef),
					return => 'single'
				};
	my $row = eval { $class->db_select($args);	};
	is( $row->[0], 0, $t . ', gone from table: ' . $class->base_table );
}

1;
