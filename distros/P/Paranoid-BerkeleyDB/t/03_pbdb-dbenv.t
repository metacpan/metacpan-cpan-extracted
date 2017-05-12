#!/usr/bin/perl -T

use Test::More tests => 13;
use Paranoid;
use Paranoid::Debug;
use Paranoid::BerkeleyDB::Db;
use Paranoid::BerkeleyDB::Env;

use strict;
use warnings;

psecureEnv();

my ( $rv, $db1, $db2, $db3, $db4, $pid, $k, $v );
my ( $dbe1, $dbe2, $dbe3 );

#PDEBUG = 20;

# Create the environments
$dbe1 = new Paranoid::BerkeleyDB::Env '-Home' => './t/db';
ok( $dbe1, 'open environment 1' );
$dbe2 = new Paranoid::BerkeleyDB::Env '-Home' => './t/db';
ok( $dbe2, 'open environment 2' );
$dbe3 = new Paranoid::BerkeleyDB::Env '-Home' => './t/db-env';
ok( $dbe3, 'open environment 3' );

# Create test database
$db1 = new Paranoid::BerkeleyDB::Db
    '-Env'      => $dbe1,
    '-Filename' => './t/db/standalone1.db';
ok( $db1, 'open database 1' );
$db2 = new Paranoid::BerkeleyDB::Db
    '-Env'      => $dbe2,
    '-Filename' => './t/db/standalone1.db';
ok( $db2, 'open database 2' );
$db3 = new Paranoid::BerkeleyDB::Db
    '-Env'      => $dbe3,
    '-Filename' => './t/db/standalone2.db';
ok( $db3, 'open database 3' );
$db4 = new Paranoid::BerkeleyDB::Db
    '-Env'      => $dbe3,
    '-Filename' => './t/db/standalone3.db';
ok( $db4, 'open database 4' );

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
$db4->dbh->db_get( 'one', $v );
is( $v, undef, 'db_get - 5' );
$db3->dbh->db_get( 'one', $v );
is( $v, 1, 'db_get - 6' );

# Cleanup
$db1 = $db2 = $db3 = $db4 = undef;
$dbe1 = $dbe2 = $dbe3 = undef;
system 'rm -rf t/db*';

