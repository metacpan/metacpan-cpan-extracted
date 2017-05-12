#!/usr/bin/perl

use strict;
use Test::More tests => 6;

my ($class, $og, $full_og);
BEGIN {
    $class = 'Net::Cisco::ObjectGroup';
    use_ok($class);
}

eval{ $og = $class->new({
    type => 'icmp',
    name => 'test_group',
    description => 'THIS IS A TEST',
    pretty_print => 1,
}) };
isa_ok( $og, "$class\::ICMP", 'new object created' );

$og->push({icmp_type => 8});
like( $og->dump, qr/\n  icmp-object echo$/, 'push 1');

$og->push({icmp_type => 'echo-reply'});
like( $og->dump, qr/\n  icmp-object echo-reply$/, 'push 2');

my $tmp_og = $class->new({type => 'icmp', name => 'referenced_group'});
$og->push({group_object => $tmp_og});
like( $og->dump, qr/\n  group-object referenced_group$/, 'push 3');

$full_og = <<'OG';
object-group icmp-type test_group
  description THIS IS A TEST
  icmp-object echo
  icmp-object echo-reply
  group-object referenced_group
OG
is( $og->dump ."\n", $full_og, 'complete group dump compared');

