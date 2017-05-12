#!/usr/bin/perl

use strict;
use Test::More tests => 6;

my ($class, $og, $full_og);
BEGIN {
    $class = 'Net::Cisco::ObjectGroup';
    use_ok($class);
}

eval{ $og = $class->new({
    type => 'protocol',
    name => 'test_group',
    description => 'THIS IS A TEST',
    pretty_print => 1,
}) };
isa_ok( $og, "$class\::Protocol", 'new object created' );

$og->push({protocol => 0});
like( $og->dump, qr/\n  protocol-object ip$/, 'push 1');

$og->push({protocol => 'gre'});
like( $og->dump, qr/\n  protocol-object gre$/, 'push 2');

my $tmp_og = $class->new({type => 'protocol', name => 'referenced_group'});
$og->push({group_object => $tmp_og});
like( $og->dump, qr/\n  group-object referenced_group$/, 'push 3');

$full_og = <<'OG';
object-group protocol test_group
  description THIS IS A TEST
  protocol-object ip
  protocol-object gre
  group-object referenced_group
OG
is( $og->dump ."\n", $full_og, 'complete group dump compared');

