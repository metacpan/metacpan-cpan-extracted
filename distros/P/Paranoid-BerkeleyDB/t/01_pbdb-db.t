#!/usr/bin/perl -T

use Test::More tests => 14;
use Paranoid;
use Paranoid::Debug;
use Paranoid::BerkeleyDB::Db;

use strict;
use warnings;

psecureEnv();

my ( $rv, $db1, $db2, $db3, $pid, $k, $v );

#PDEBUG = 20;

# Create test database
$db1 = new Paranoid::BerkeleyDB::Db '-Filename' => './t/db/standalone1.db';
ok( $db1, 'open database 1' );
$db2 = new Paranoid::BerkeleyDB::Db '-Filename' => './t/db/standalone1.db';
ok( $db2, 'open database 2' );
$db3 = new Paranoid::BerkeleyDB::Db '-Filename' => './t/db/standalone2.db';
ok( $db3, 'open database 3' );

# Compare refs and counts
is( $db1->dbh, $db2->dbh, 'duplicate dbh - 1' );
isnt( $db1->dbh, $db3->dbh, 'duplicate dbh - 2' );
is( $db1->refc, 2, 'ref count - 1' );
is( $db2->refc, 2, 'ref count - 2' );
is( $db3->refc, 1, 'ref count - 3' );

# Stuff some values in and make sure the view is consistent
$db1->dbh->db_put( 'foo', 'bar' );
$db2->dbh->db_get( 'foo', $v );
is( $v, 'bar', 'db_get - 1' );
$db2->dbh->db_put( 'bar', 'roo' );
$db1->dbh->db_get( 'bar', $v );
is( $v, 'roo', 'db_get - 2' );
$db3->dbh->db_put( 'one', 1 );
$v = undef;
$db1->dbh->db_get( 'one', $v );
is( $v, undef, 'db_get - 3' );
$db2->dbh->db_get( 'one', $v );
is( $v, undef, 'db_get - 4' );
$db3->dbh->db_get( 'one', $v );
is( $v, 1, 'db_get - 5' );

# Test bad invocation
$db3 = new Paranoid::BerkeleyDB::Db;
is( $db3, undef, 'bad invocation - 1' );

# Cleanup
$db1 = $db2 = $db3 = undef;
system 'rm -rf t/db*';

