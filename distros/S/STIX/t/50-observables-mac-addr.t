#!perl

use strict;
use warnings;
use v5.10;

use Test::More;

use STIX ':sco';
use Time::Piece;


my $object = mac_addr(value => 'd2:fb:49:24:37:18');

my @errors = $object->validate;

diag 'Typical MAC address', "\n", "$object";

isnt "$object", '';

is $object->type, 'mac-addr';

is @errors, 0;

done_testing();
