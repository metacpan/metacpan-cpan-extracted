#!/usr/bin/perl

use strict;
use Test::More tests => 6;

my ($class, $og, $full_og);
BEGIN {
    $class = 'Net::Cisco::ObjectGroup';
    use_ok($class);
}

eval{ $og = $class->new({
    type => 'network',
    name => 'test_group',
    description => 'THIS IS A TEST',
}) };
isa_ok( $og, "$class\::Network", 'new object created' );

$og->push({net_addr => '123.123.123.123'});
like( $og->dump, qr/\n  network-object host 123.123.123.123$/, 'push 1');

$og->push({net_addr => '123.123.0.0', netmask => '255.255.0.0'});
like( $og->dump, qr/\n  network-object 123.123.0.0 255.255.0.0$/, 'push 2');

my $tmp_og = $class->new({type => 'network', name => 'referenced_group'});
$og->push({group_object => $tmp_og});
like( $og->dump, qr/\n  group-object referenced_group$/, 'push 3');

$full_og = <<'OG';
object-group network test_group
  description THIS IS A TEST
  network-object host 123.123.123.123
  network-object 123.123.0.0 255.255.0.0
  group-object referenced_group
OG
is( $og->dump ."\n", $full_og, 'complete group dump compared');

