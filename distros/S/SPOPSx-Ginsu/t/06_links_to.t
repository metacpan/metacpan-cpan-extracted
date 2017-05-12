#!/usr/bin/perl -w

BEGIN {
	use lib qw( t );
}

use strict;
use Test::More tests => 19;

use my_dbi_conf;
use test_config;
test_config->recreate_tables;
require 'fill_tables.pl';

my ($c, $clubs, $p, $persons);

##-----  fetch methods  -----
my $t = 'fetch methods';
$p = Person->fetch(20);
ok( $clubs = $p->ClubAlias, $t );
is( @$clubs, 2, $t );
is_deeply( [sort map $_->id, @$clubs], [26, 27], $t );

$c = Club->fetch(26);
ok( $persons = $c->PersonAlias, $t );
is( @$persons, 3, $t );
is_deeply( [sort map $_->id, @$persons], [20, 21, 24], $t );

##-----  add methods  -----
$t = 'add methods';
$p = Person->fetch(20);
$p->ClubAlias_add([28]);
ok( $clubs = $p->ClubAlias, $t );
is( @$clubs, 3, $t );
is_deeply( [sort map $_->id, @$clubs], [26, 27, 28], $t );

$c = Club->fetch(26);
$c->PersonAlias_add( [22,25] );
ok( $persons = $c->PersonAlias, $t );
is( @$persons, 5, $t );
is_deeply( [sort map $_->id, @$persons], [20, 21, 22, 24, 25], $t );

##-----  remove methods  -----
$t = 'remove methods';
$p = Person->fetch(20);
$p->ClubAlias_remove([28]);
ok( $clubs = $p->ClubAlias, $t );
is( @$clubs, 2, $t );
is_deeply( [sort map $_->id, @$clubs], [26, 27], $t );

$c = Club->fetch(26);
$c->PersonAlias_remove( [22,25] );
ok( $persons = $c->PersonAlias, $t );
is( @$persons, 3, $t );
is_deeply( [sort map $_->id, @$persons], [20, 21, 24], $t );

##-----  auto-removal of linking entries  -----
$t = 'auto-removal of linking entries';
$c->remove;
my $args = {	from => [ 'ClubMembers' ],
				select => [ 'COUNT(*)'],
				where => 'club_id = 26',
				return => 'single'
			};
my $row = eval { ClubMembers->db_select($args); };
is( $row->[0], 0, $t );

1;

