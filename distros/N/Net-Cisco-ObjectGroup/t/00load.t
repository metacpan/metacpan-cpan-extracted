#!/usr/bin/perl

use strict;
use Test::More tests => 11;

my ($class, $og);
BEGIN {
    $class = 'Net::Cisco::ObjectGroup';
    use_ok($class);
}

eval{ $og = $class->new };
like( $@, qr/^missing parameter "type"/, 'dies with no type' );

eval{ $og = $class->new({type => 'SOSSIES'}) };
like( $@, qr/^unrecognized object-group type: 'SOSSIES'/, 'dies with unk type' );

eval{ $og = $class->new({type => 'icmp'}) };
like( $@, qr/^missing parameter "name"/, 'dies with no name' );

eval{ $og = $class->new({type => 'icmp', name => ''}) };
like( $@, qr/^bad object-group name: ''/, 'dies with bad name' );

eval{ $og = $class->new({type => 'icmp', name => 'sdf££ASDF'}) };
like( $@, qr/^bad object-group name: 'sdf££ASDF'/, 'dies with bad name' );

eval{ $og = $class->new({type => 'icmp', name => 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'}) };
like( $@, qr/^bad object-group name: 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'/, 'dies with bad name' );

eval{ $og = $class->new({type => 'icmp', name => 'test_group'}) };
isa_ok( $og, "$class\::ICMP", 'new object created' );

can_ok( $og, 'dump' );
is( $og->dump, 'object-group icmp-type test_group', 'dump empty group' );

eval{ $og = $class->new({type => 'icmp', name => 'test_group', description => 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'}) };
like( $@, qr/^bad description/, 'dies with bad description' );

