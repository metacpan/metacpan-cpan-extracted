#!/usr/bin/perl -T

use Test::More tests => 15;
use Paranoid;
use Paranoid::Debug;
use Parse::PlainConfig;

use strict;
use warnings;

psecureEnv();

use lib qw(t/lib);
use CStyle;

my $obj = new CStyle;
ok( defined $obj, 'new object - 1' );
ok( $obj->read('t/lib/unix.conf'), 'config read');
my $val = $obj->get('admin email');
is( $val, 'foo@bar.com', 'default scalar retrieval' );
my @val = $obj->get('hosts');
is( $val[0], 'host1.foo.com', 'default array retrieval' );
my %val = $obj->get('db');
is( $val{database}, 'mydb.db', 'default hash retrieval' );
$val = $obj->get('note');
ok( length $val, 'default hdoc retrieval' );
($val) = $obj->get('loopback');
is( $val, '127.0.0.1', 'default proto retrieval' );
$val = $obj->get('nodefault');
is( $val, 'whoops!', 'nodefault retrieval' );
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

