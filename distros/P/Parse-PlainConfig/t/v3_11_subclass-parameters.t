#!/usr/bin/perl -T

use Test::More tests => 25;
use Paranoid;
use Paranoid::Debug;
use Parse::PlainConfig;

use strict;
use warnings;

psecureEnv();

use lib qw(t/lib);
use MyConf2;

#PDEBUG = 20;
my $obj = new MyConf2;
ok( defined $obj, 'new object - 1' );
my $val = $obj->get('admin email');
is( $val, 'root@yourhost', 'default scalar retrieval' );
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
ok( $obj->set( 'nodefault', 'set' ), 'set parameter' );
$val = $obj->get('nodefault');
is( $val, 'set', 'get parameter' );
ok( $obj->set( 'loopback', $obj->get('localnet') ), 'set prototype' );
($val) = $obj->get('loopback');
is( $val, '192.168.0.0/24', 'get prototype' );

$val = [ $obj->prototyped ];
is( scalar @$val, 4, 'prototyped all 1' );
ok( ( scalar grep { $_ eq 'loopback' } @$val ), 'prototyped all 2' );
$val = [ $obj->prototyped('declare acl') ];
is( scalar @$val, 2, 'prototyped specific 1' );
ok( ( scalar grep { $_ eq 'loopback' } @$val ), 'prototyped specific 2' );
$val = [ $obj->prototyped('declare foo') ];
is( scalar @$val, 1, 'prototyped specific 3' );
ok( ( scalar grep { $_ eq 'bar' } @$val ), 'prototyped specific 4' );

ok( $obj->reset, 'reset config' );
$val = $obj->get('nodefault');
ok( !defined $val, 'nodefault retrieval 2' );
($val) = $obj->get('loopback');
is( $val, '127.0.0.1', 'default proto retrieval 2' );

#PDEBUG = 9;
ok( !$obj->parse('gack! Spurious text!!!'),   'spurious text 1' );
ok( !$obj->parse('declare acl db foo'),       'proto/prop conflict 1' );
ok( !$obj->parse('declare foo localnet bar'), 'proto/prop conflict 2' );
ok( !$obj->set( 'admin user', 'foo' ), 'invalid prop 1' );
ok( !$obj->get('admin user'), 'invalid prop 2' );

