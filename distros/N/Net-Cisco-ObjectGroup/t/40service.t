#!/usr/bin/perl

use strict;
use Test::More tests => 6;

my ($class, $og, $full_og);
BEGIN {
    $class = 'Net::Cisco::ObjectGroup';
    use_ok($class);
}

eval{ $og = $class->new({
    type => 'service',
    name => 'test_group',
    protocol => 'tcp-udp',
    description => 'THIS IS A TEST',
    pretty_print => 1,
}) };
isa_ok( $og, "$class\::Service", 'new object created' );

$og->push({svc_op => 'eq', svc => '53'});
like( $og->dump, qr/\n  port-object eq domain$/, 'push 1');

$og->push({svc_op => 'range', svc => 'telnet', svc_hi => 'smtp'});
like( $og->dump, qr/\n  port-object range telnet smtp$/, 'push 2');

my $tmp_og = $class->new({
    type => 'service',
    name => 'referenced_group',
    protocol => 'udp',
});
$og->push({group_object => $tmp_og});
like( $og->dump, qr/\n  group-object referenced_group$/, 'push 3');

$full_og = <<'OG';
object-group service test_group tcp-udp
  description THIS IS A TEST
  port-object eq domain
  port-object range telnet smtp
  group-object referenced_group
OG
is( $og->dump ."\n", $full_og, 'complete group dump compared');

