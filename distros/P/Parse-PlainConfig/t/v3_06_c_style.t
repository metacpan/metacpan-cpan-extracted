#!/usr/bin/perl -T

use Test::More tests => 19;
use Paranoid;
use Paranoid::Debug;
use Parse::PlainConfig;

use strict;
use warnings;

psecureEnv();

use lib qw(t/lib);
use CStyle;

#PDEBUG = 20;
my $obj = new CStyle;
ok( defined $obj, 'new object - 1' );
my $val = $obj->get('admin email');
is( $val, 'root@localhost', 'default scalar retrieval' );
my @val = $obj->get('hosts');
is( $val[0], 'localhost', 'default array retrieval' );
my %val = $obj->get('db');
is( $val{database}, 'sample.db', 'default hash retrieval' );
$val = $obj->get('note');
ok( length $val, 'default hdoc retrieval' );
($val) = $obj->get('loopback');
is( $val, '127.0.0.1', 'default proto retrieval' );
$val = $obj->get('nodefault');
ok( !defined $val, 'nodefault retrieval' );
ok( $obj->set('nodefault', 'set'), 'set parameter');
$val = $obj->get('nodefault');
is( $val, 'set', 'get parameter' );
ok( $obj->set('loopback', $obj->get('localnet')), 'set prototype');
($val) = $obj->get('loopback');
is( $val, '192.168.0.0/24', 'get prototype');

ok($obj->reset, 'reset config');
$val = $obj->get('nodefault');
ok( !defined $val, 'nodefault retrieval 2' );
($val) = $obj->get('loopback');
is( $val, '127.0.0.1', 'default proto retrieval 2' );

#PDEBUG = 9;
ok(! $obj->parse('gack! Spurious text!!!'), 'spurious text 1');
ok(! $obj->parse('declare acl db := foo'), 'proto/prop conflict 1');
ok(! $obj->parse('declare foo localnet := bar'), 'proto/prop conflict 2');
ok(! $obj->set('admin user', 'foo'), 'invalid prop 1');
ok(! $obj->get('admin user'), 'invalid prop 2');

