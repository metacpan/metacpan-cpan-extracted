#!perl

use strict;
use warnings;
use v5.10;

use Test::More;

use STIX ':sco';
use Time::Piece;


my $object = ipv6_addr(value => '2001:0db8::/96');

my @errors = $object->validate;

diag 'IPv6 CIDR block', "\n", "$object";

isnt "$object", '';

is $object->type, 'ipv6-addr';

is @errors, 0;

done_testing();
