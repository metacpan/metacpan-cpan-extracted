#!perl

use strict;
use warnings;
use v5.10;

use Test::More;

use STIX::Common::Bundle;
use STIX::Observable::IPv4Addr;
use STIX::Observable::NetworkTraffic;


my $ipv4_1 = STIX::Observable::IPv4Addr->new(value => '198.51.100.2');
my $ipv4_2 = STIX::Observable::IPv4Addr->new(value => '198.51.100.3');

my $network_traffic
    = STIX::Observable::NetworkTraffic->new(src_ref => $ipv4_1, dst_ref => $ipv4_2, protocols => ['tcp']);

my $object = STIX::Common::Bundle->new(objects => [$ipv4_1, $ipv4_2, $network_traffic]);

my @errors = $object->validate;

diag 'Basic TCP Network Traffic', "\n", "$object";

isnt "$object", '';

is $object->type,               'bundle';
is $object->objects->[0]->type, 'ipv4-addr';
is $object->objects->[1]->type, 'ipv4-addr';
is $object->objects->[2]->type, 'network-traffic';

is @errors, 0;

done_testing();
