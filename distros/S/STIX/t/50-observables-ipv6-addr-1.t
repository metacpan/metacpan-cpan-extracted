#!perl

use strict;
use warnings;
use v5.10;

use Test::More;

use STIX ':sco';
use Time::Piece;


my $object = ipv6_addr(value => '2001:0db8:85a3:0000:0000:8a2e:0370:7334');

my @errors = $object->validate;

diag 'IPv6 Single Address', "\n", "$object";

isnt "$object", '';

is $object->type, 'ipv6-addr';

is @errors, 0;

done_testing();
