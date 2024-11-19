#!perl

use strict;
use warnings;
use v5.10;

use Test::More;

use STIX ':sco';


my $object = windows_registry_key(key => 'HKEY_LOCAL_MACHINE\\System\\Foo\\Bar');

my @errors = $object->validate;

diag 'Registry key with values', "\n", "$object";

isnt "$object", '';

is $object->type, 'windows-registry-key';

is @errors, 0;

done_testing();
