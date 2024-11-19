#!perl

use strict;
use warnings;
use v5.10;

use Test::More;

use STIX qw(:sco bundle);


my $domain_name     = domain_name(value => 'example.com');
my $network_traffic = network_traffic(dst_ref => $domain_name, protocols => [qw[ipv4 tcp http]]);

my $object = bundle(objects => [$domain_name, $network_traffic]);

my @errors = $object->validate;

diag 'Basic HTTP Network Traffic', "\n", "$object";

isnt "$object", '';

is $object->type,               'bundle';
is $object->objects->[0]->type, 'domain-name';
is $object->objects->[1]->type, 'network-traffic';

is @errors, 0;

done_testing();
