#!perl

use strict;
use warnings;
use v5.10;

use Test::More;

use STIX qw(:sco bundle);


my $ipv4_1 = ipv4_addr(value => '203.0.113.1');
my $ipv4_2 = ipv4_addr(value => '203.0.113.5');

my $network_traffic = network_traffic(
    src_ref        => $ipv4_1,
    dst_ref        => $ipv4_2,
    protocols      => ['ipv4', 'tcp'],
    src_byte_count => 147_600,
    src_packets    => 100,
    ipfix          => {minimumIpTotalLength => 32, maximumIpTotalLength => 2556}
);

my $object = bundle(objects => [$ipv4_1, $ipv4_2, $network_traffic]);

my @errors = $object->validate;

diag 'Network Traffic with Netflow Data', "\n", "$object";

isnt "$object", '';

is $object->type,               'bundle';
is $object->objects->[0]->type, 'ipv4-addr';
is $object->objects->[1]->type, 'ipv4-addr';
is $object->objects->[2]->type, 'network-traffic';

is @errors, 0;

done_testing();
