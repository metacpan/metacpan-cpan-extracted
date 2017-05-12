#!/usr/bin/perl

use strict;
use Test::More tests => 21;

my ($class, $og);
BEGIN {
    $class = 'Net::Cisco::ObjectGroup';
    use_ok($class);
}

eval{ $og = $class->new({type => 'icmp', name => 'test_group'}) };
isa_ok( $og, "$class\::ICMP", 'new object created' );

eval{ $og->push({}) };
like( $@, qr/^must specify either group-object or ICMP type/, 'must specify either group-object or ICMP type' );

eval{ $og->push({icmp_type => 8, group_object => $og}) };
like( $@, qr/^cannot specify both group-object and ICMP type/, 'cannot specify both group-object and ICMP type' );

eval{ $og->push({group_object => 'foo'}) };
like( $@, qr/^bad group-object/, 'bad group-object' );



eval{ $og = $class->new({type => 'network', name => 'test_group'}) };
isa_ok( $og, "$class\::Network", 'new object created' );

eval{ $og->push({}) };
like( $@, qr/^must specify either group-object or IP network/, 'must specify either group-object or IP network' );

eval{ $og->push({net_addr => '123.123.123.123', group_object => $og}) };
like( $@, qr/^cannot specify both group-object and IP network/, 'cannot specify both group-object and IP network' );

eval{ $og->push({group_object => 'foo'}) };
like( $@, qr/^bad group-object/, 'bad group-object' );



eval{ $og = $class->new({type => 'protocol', name => 'test_group'}) };
isa_ok( $og, "$class\::Protocol", 'new object created' );

eval{ $og->push({}) };
like( $@, qr/^must specify either group-object or protocol/, 'must specify either group-object or protocol' );

eval{ $og->push({protocol => 8, group_object => $og}) };
like( $@, qr/^cannot specify both group-object and protocol/, 'cannot specify both group-object and protocol' );

eval{ $og->push({group_object => 'foo'}) };
like( $@, qr/^bad group-object/, 'bad group-object' );



eval{ $og = $class->new({type => 'service', name => 'test_group'}) };
like( $@, qr/^missing parameter "protocol" when creating service group/, 'missing parameter "protocol" when creating service group' );

eval{ $og = $class->new({type => 'service', name => 'test_group', protocol => 'bar'}) };
like( $@, qr/^unrecognized protocol type: /, 'unrecognized protocol type' );

eval{ $og = $class->new({type => 'service', name => 'test_group', protocol => 'udp'}) };
isa_ok( $og, "$class\::Service", 'new object created' );

eval{ $og->push({}) };
like( $@, qr/^must specify either group-object or service definition/, 'must specify either group-object or service definition' );

eval{ $og->push({svc => 25, group_object => $og}) };
like( $@, qr/^cannot specify both group-object and service definition/, 'cannot specify both group-object and service definition' );

eval{ $og->push({svc => 25}) };
like( $@, qr/^missing service operator/, 'missing service operator' );

eval{ $og->push({svc => 25, svc_op => 'baz'}) };
like( $@, qr/^unrecognized service operator/, 'unrecognized service operator' );

eval{ $og->push({group_object => 'foo'}) };
like( $@, qr/^bad group-object/, 'bad group-object' );

