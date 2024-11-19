#!perl

use strict;
use warnings;
use v5.10;

use Test::More;

use STIX ':sco';
use Time::Piece;


my $object = ipv4_addr(value => '198.51.100.0/24');

my @errors = $object->validate;

diag 'IPv4 CIDR block', "\n", "$object";

isnt "$object", '';

is $object->type, 'ipv4-addr';

is @errors, 0;

done_testing();
