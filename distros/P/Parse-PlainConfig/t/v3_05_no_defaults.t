#!/usr/bin/perl -T

use Test::More tests => 14;
use Paranoid;
use Paranoid::Debug;
use Parse::PlainConfig;

use strict;
use warnings;

psecureEnv();

use lib qw(t/lib);
use NoDefaults;

#PDEBUG = 20;
my $obj = new NoDefaults;
ok( defined $obj, 'new object - 1' );
my $val = $obj->get('admin email');
is( $val, undef, 'default scalar retrieval' );
my @val = $obj->get('hosts');
is( $val[0], undef, 'default array retrieval' );
my %val = $obj->get('db');
is( $val{database}, undef, 'default hash retrieval' );
$val = $obj->get('note');
ok( !length $val, 'default hdoc retrieval' );
($val) = $obj->get('loopback');
is( $val, undef, 'default proto retrieval' );
$val = $obj->get('nodefault');
ok( !defined $val, 'nodefault retrieval' );
ok( $obj->set('nodefault', 'set'), 'set parameter');
$val = $obj->get('nodefault');
is( $val, 'set', 'get parameter' );

ok($obj->reset, 'reset config');
$val = $obj->get('nodefault');
ok( !defined $val, 'nodefault retrieval 2' );

#PDEBUG = 9;
ok(! $obj->parse('gack! Spurious text!!!'), 'spurious text 1');
ok(! $obj->set('admin user', 'foo'), 'invalid prop 1');
ok(! $obj->get('admin user'), 'invalid prop 2');

