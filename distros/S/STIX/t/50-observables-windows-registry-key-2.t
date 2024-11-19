#!perl

use strict;
use warnings;
use v5.10;

use Test::More;

use STIX ':sco';


my $object = windows_registry_key(
    key    => 'HKEY_LOCAL_MACHINE\\System\\Foo\\Bar',
    values => [
        windows_registry_value_type(name => 'Foo', data => 'querty', data_type => 'REG_SZ'),
        windows_registry_value_type(name => 'Foo', data => '42',     data_type => 'REG_DWORD'),
    ]
);

my @errors = $object->validate;

diag 'Registry key with values', "\n", "$object";

isnt "$object", '';

is $object->type, 'windows-registry-key';

is @errors, 0;

done_testing();
