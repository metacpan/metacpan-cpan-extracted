#!/usr/bin/perl

use strict;
use Test::More tests => 12;

my ($class, $l);
BEGIN {
    $class = 'Net::Cisco::AccessList::Extended';
    use_ok($class);
}

eval{ $l = $class->new('TEST_LIST') };
isa_ok( $l, $class, 'new object created' );

is( $l->dump, '', 'dump empty list' );

$l->push({access => 'permit', proto => 'ip'});
is( $l->dump, 'access-list TEST_LIST extended permit ip any any', 'dump simplest list');

$l->push({access => 'permit', proto => 'ip'});
like( $l->dump, qr/\naccess-list TEST_LIST extended permit ip any any$/, 'push 5');

$l->push({access => '1', proto => 'ip', src_og => 'srcnet', dst_og => 'dstnet'});
like( $l->dump, qr/\naccess-list TEST_LIST extended permit ip object-group srcnet object-group dstnet$/, 'push 6');

$l->push({access => 'Permit', proto => 'ip', src_svc_og => 'srcprt', dst_svc_og => 'dstprt'});
like( $l->dump, qr/\naccess-list TEST_LIST extended permit ip any object-group srcprt any object-group dstprt$/, 'push 7');

$l->push({access => 'deny', proto => 'icmp', icmp_og => 'icmptypes'});
like( $l->dump, qr/\naccess-list TEST_LIST extended deny icmp any any object-group icmptypes$/, 'push 8');

$l->push({access => 'false', proto => 'icmp', icmp => 'echo-request'});
like( $l->dump, qr/\naccess-list TEST_LIST extended deny icmp any any echo-request$/, 'push 9');

$l->push({access => '0', proto => 'ip', src_svc_op => 'range', src_svc => 'telnet', src_svc_hi => 'smtp'});
like( $l->dump, qr/\naccess-list TEST_LIST extended deny ip any range telnet smtp any$/, , 'push 10');

$l->push({access => 'permit', proto => 'ip', dst_svc_op => 'range', dst_svc => 'telnet', dst_svc_hi => 'smtp'});
like( $l->dump, qr/\naccess-list TEST_LIST extended permit ip any any range telnet smtp$/, 'push 11');

my $full_acl = <<'ACE';
access-list TEST_LIST extended permit ip any any
access-list TEST_LIST extended permit ip any any
access-list TEST_LIST extended permit ip object-group srcnet object-group dstnet
access-list TEST_LIST extended permit ip any object-group srcprt any object-group dstprt
access-list TEST_LIST extended deny icmp any any object-group icmptypes
access-list TEST_LIST extended deny icmp any any echo-request
access-list TEST_LIST extended deny ip any range telnet smtp any
access-list TEST_LIST extended permit ip any any range telnet smtp
ACE

is( $l->dump ."\n", $full_acl, 'complete list dump compared');

