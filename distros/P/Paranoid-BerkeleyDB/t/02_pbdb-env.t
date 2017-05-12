#!/usr/bin/perl -T

use Test::More tests => 9;
use Paranoid;
use Paranoid::Debug;
use Paranoid::BerkeleyDB::Env;

use strict;
use warnings;

psecureEnv();

my ( $rv, $dbe1, $dbe2, $dbe3, $pid, $k, $v );

#PDEBUG = 20;

# Create test database
$dbe1 = new Paranoid::BerkeleyDB::Env '-Home' => './t/db';
ok( $dbe1, 'open environment 1' );
$dbe2 = new Paranoid::BerkeleyDB::Env '-Home' => './t/db';
ok( $dbe2, 'open environment 2' );
$dbe3 = new Paranoid::BerkeleyDB::Env '-Home' => './t/db-env';
ok( $dbe3, 'open environment 3' );

# Compare refs and counts
is( $dbe1->env, $dbe2->env, 'duplicate env - 1' );
isnt( $dbe1->env, $dbe3->env, 'duplicate env - 2' );
is( $dbe1->refc, 2, 'ref count - 1' );
is( $dbe2->refc, 2, 'ref count - 2' );
is( $dbe3->refc, 1, 'ref count - 3' );

# Test bad invocation
$dbe3 = new Paranoid::BerkeleyDB::Env;
is( $dbe3, undef, 'bad invocation - 1' );

# Cleanup
$dbe1 = $dbe2 = $dbe3 = undef;
system 'rm -rf t/db*';

