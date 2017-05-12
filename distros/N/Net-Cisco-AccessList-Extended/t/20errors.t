#!/usr/bin/perl

use strict;
use Test::More tests => 27;

my ($class, $l);
BEGIN {
    $class = 'Net::Cisco::AccessList::Extended';
    use_ok($class);
}

eval{ $l = $class->new('TEST_LIST') };
isa_ok( $l, $class, 'new object created' );

is( $l->dump, '', 'dump empty list' );

eval{ $l->push() };
like( $@, qr/^missing parameter "access"/, 'missing parameter "access"');

eval{ $l->push({}) };
like( $@, qr/^missing parameter "access"/, 'missing parameter "access"');

eval{ $l->push({access => 'permit'}) };
like( $@, qr/^missing parameter "proto" or "proto_og"/, 'missing parameter "proto" or "proto_og"');

eval{ $l->push({access => 'permit', proto => 'ip', proto_og => 'bar'}) };
like( $@, qr/^cannot specify both protocol and protocol group/, 'cannot specify both protocol and protocol group');

eval{ $l->push({access => 'permit', proto => 'ip', src_mask => '255.255.255.0'}) };
like( $@, qr/^missing source network address/, 'missing source network address');
eval{ $l->push({access => 'permit', proto => 'ip', dst_mask => '255.255.255.0'}) };
like( $@, qr/^missing destination network address/, 'missing destination network address');

eval{ $l->push({access => 'permit', proto => 'ip', src_ip => '123.123.123.123', src_og => 'srcnet'}) };
like( $@, qr/^cannot specify both source network and network group/, 'cannot specify both source network and network group');
eval{ $l->push({access => 'permit', proto => 'ip', dst_ip => '213.213.213.213', dst_og => 'dstnet'}) };
like( $@, qr/^cannot specify both destination network and network group/, 'cannot specify both destination network and network group');

eval{ $l->push({access => 'permit', proto => 'ip', src_svc_op => 'range', src_svc_hi => 'stmp'}) };
like( $@, qr/^missing low service for source service range/, 'missing low service for source service range');
eval{ $l->push({access => 'permit', proto => 'ip', src_svc => 'telnet'}) };
like( $@, qr/^missing source service operator/, 'missing source service operator');
eval{ $l->push({access => 'permit', proto => 'ip', src_svc_og => 'srcprt', src_svc => 'dstprt', src_svc_op => 'eq'}) };
like( $@, qr/^cannot specify both source service and service group/, 'cannot specify both source service and service group');

eval{ $l->push({access => 'permit', proto => 'ip', dst_svc_op => 'range', dst_svc_hi => 'stmp'}) };
like( $@, qr/^missing low service for destination service range/, 'missing low service for destination service range');
eval{ $l->push({access => 'permit', proto => 'ip', dst_svc => 'telnet'}) };
like( $@, qr/^missing destination service operator/, 'missing destination service operator');
eval{ $l->push({access => 'permit', proto => 'ip', dst_svc_og => 'dstprt', dst_svc => 'dstprt', dst_svc_op => 'lt'}) };
like( $@, qr/^cannot specify both destination service and service group/, 'cannot specify both destination service and service group');

eval{ $l->push({access => 'permit', proto => 'ip', icmp => 'echo-request', icmp_og => 'icmptypes'}) };
like( $@, qr/^cannot specify both icmp type and icmp group/, 'cannot specify both icmp type and icmp group');

eval{ $l->push({access => 'permit', proto => 'ip', icmp => 'echo-request', src_svc_op => 'eq'}) };
like( $@, qr/^cannot use icmp with services/, 'cannot use icmp with services');
eval{ $l->push({access => 'permit', proto => 'ip', icmp => 'echo-request', src_svc_og => 'prtgrp'}) };
like( $@, qr/^cannot use icmp with services/, 'cannot use icmp with services');
eval{ $l->push({access => 'permit', proto => 'ip', icmp => 'echo-request', dst_svc_op => 'gt'}) };
like( $@, qr/^cannot use icmp with services/, 'cannot use icmp with services');
eval{ $l->push({access => 'permit', proto => 'ip', icmp => 'echo-request', dst_svc_og => 'prtgrp'}) };
like( $@, qr/^cannot use icmp with services/, 'cannot use icmp with services');

eval{ $l->push({access => 'permit', proto => 'ip', icmp_og => 'icmptypes', src_svc_op => 'eq'}) };
like( $@, qr/^cannot use icmp with services/, 'cannot use icmp with services');
eval{ $l->push({access => 'permit', proto => 'ip', icmp_og => 'icmptypes', src_svc_og => 'prtgrp'}) };
like( $@, qr/^cannot use icmp with services/, 'cannot use icmp with services');
eval{ $l->push({access => 'permit', proto => 'ip', icmp_og => 'icmptypes', dst_svc_op => 'gt'}) };
like( $@, qr/^cannot use icmp with services/, 'cannot use icmp with services');
eval{ $l->push({access => 'permit', proto => 'ip', icmp_og => 'icmptypes', dst_svc_og => 'prtgrp'}) };
like( $@, qr/^cannot use icmp with services/, 'cannot use icmp with services');

is( $l->dump, '', 'dump empty list');

